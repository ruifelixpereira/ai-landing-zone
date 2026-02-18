#!/bin/bash
# =============================================================================
# Setup Azure Service Principal with GitHub OIDC Federation
# This script creates a Service Principal and configures federated credentials
# for GitHub Actions, eliminating the need for client secrets.
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# Load .env file if it exists
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
    echo -e "${YELLOW}Loading configuration from $ENV_FILE${NC}"
    # Export variables from .env file (ignore comments and empty lines)
    set -a
    source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
    set +a
fi

# =============================================================================
# Configuration - UPDATE THESE VALUES
# =============================================================================
GITHUB_ORG="${GITHUB_ORG:-}"              # e.g., "myorg" or "myusername"
GITHUB_REPO="${GITHUB_REPO:-}"            # e.g., "ai-landing-zone"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"    # Azure Subscription ID
APP_NAME="${APP_NAME:-github-ai-landing-zone}"
LOCATION="${LOCATION:-swedencentral}"

# =============================================================================
# Functions
# =============================================================================

print_usage() {
    echo "Usage: $0"
    echo ""
    echo "Configuration can be provided via:"
    echo "  1. .env file in the scripts directory (recommended)"
    echo "  2. Environment variables"
    echo ""
    echo "Required variables:"
    echo "  GITHUB_ORG        - GitHub organization or username"
    echo "  GITHUB_REPO       - GitHub repository name"
    echo "  SUBSCRIPTION_ID   - Azure Subscription ID"
    echo ""
    echo "Optional variables:"
    echo "  APP_NAME          - Azure AD App name (default: github-ai-landing-zone)"
    echo "  LOCATION          - Azure region (default: swedencentral)"
    echo "  ENV_FILE          - Path to .env file (default: scripts/.env)"
    echo ""
    echo "Examples:"
    echo "  # Using .env file (copy .env.example to .env and edit)"
    echo "  cp scripts/.env.example scripts/.env"
    echo "  ./scripts/setup-github-oidc.sh"
    echo ""
    echo "  # Using environment variables"
    echo "  GITHUB_ORG=myorg GITHUB_REPO=ai-landing-zone SUBSCRIPTION_ID=xxx ./scripts/setup-github-oidc.sh"
}

check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI is not installed${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed${NC}"
        exit 1
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        echo -e "${RED}Error: Not logged in to Azure CLI. Run 'az login' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Requirements met.${NC}"
}

validate_inputs() {
    if [[ -z "$GITHUB_ORG" ]]; then
        echo -e "${RED}Error: GITHUB_ORG is required${NC}"
        print_usage
        exit 1
    fi
    
    if [[ -z "$GITHUB_REPO" ]]; then
        echo -e "${RED}Error: GITHUB_REPO is required${NC}"
        print_usage
        exit 1
    fi
    
    if [[ -z "$SUBSCRIPTION_ID" ]]; then
        echo -e "${RED}Error: SUBSCRIPTION_ID is required${NC}"
        print_usage
        exit 1
    fi
}

# =============================================================================
# Main Script
# =============================================================================

echo "=============================================="
echo "Azure Service Principal + GitHub OIDC Setup"
echo "=============================================="
echo ""

check_requirements
validate_inputs

echo ""
echo "Configuration:"
echo "  GitHub Org/User:  $GITHUB_ORG"
echo "  GitHub Repo:      $GITHUB_REPO"
echo "  Subscription ID:  $SUBSCRIPTION_ID"
echo "  App Name:         $APP_NAME"
echo ""

# Set subscription
echo -e "${YELLOW}Setting subscription...${NC}"
az account set --subscription "$SUBSCRIPTION_ID"

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "  Tenant ID: $TENANT_ID"

# =============================================================================
# Create Azure AD Application
# =============================================================================
echo ""
echo -e "${YELLOW}Creating Azure AD Application...${NC}"

# Check if app already exists
EXISTING_APP=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv 2>/dev/null || true)

if [[ -n "$EXISTING_APP" ]]; then
    echo "  App already exists with ID: $EXISTING_APP"
    CLIENT_ID="$EXISTING_APP"
else
    CLIENT_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
    echo -e "${GREEN}  Created App with ID: $CLIENT_ID${NC}"
fi

# =============================================================================
# Create Service Principal
# =============================================================================
echo ""
echo -e "${YELLOW}Creating Service Principal...${NC}"

EXISTING_SP=$(az ad sp list --filter "appId eq '$CLIENT_ID'" --query "[0].id" -o tsv 2>/dev/null || true)

if [[ -n "$EXISTING_SP" ]]; then
    echo "  Service Principal already exists"
    SP_OBJECT_ID="$EXISTING_SP"
else
    SP_OBJECT_ID=$(az ad sp create --id "$CLIENT_ID" --query id -o tsv)
    echo -e "${GREEN}  Created Service Principal${NC}"
fi

# =============================================================================
# Assign Roles
# =============================================================================
echo ""
echo -e "${YELLOW}Assigning roles...${NC}"

# Contributor role for resource deployment
echo "  Assigning Contributor role..."
az role assignment create \
    --assignee "$CLIENT_ID" \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --only-show-errors 2>/dev/null || echo "    (Role may already exist)"

# User Access Administrator for policy assignments
echo "  Assigning User Access Administrator role..."
az role assignment create \
    --assignee "$CLIENT_ID" \
    --role "User Access Administrator" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --only-show-errors 2>/dev/null || echo "    (Role may already exist)"

echo -e "${GREEN}  Roles assigned${NC}"

# =============================================================================
# Create Federated Credentials
# =============================================================================
echo ""
echo -e "${YELLOW}Creating Federated Credentials for GitHub OIDC...${NC}"

# Federated credential for main branch (push events)
CRED_NAME_MAIN="github-main-branch"
echo "  Creating credential for main branch..."
az ad app federated-credential create \
    --id "$CLIENT_ID" \
    --parameters '{
        "name": "'"$CRED_NAME_MAIN"'",
        "issuer": "https://token.actions.githubusercontent.com",
        "subject": "repo:'"$GITHUB_ORG"'/'"$GITHUB_REPO"':ref:refs/heads/main",
        "audiences": ["api://AzureADTokenExchange"]
    }' 2>/dev/null || echo "    (Credential may already exist)"

# Federated credential for pull requests
CRED_NAME_PR="github-pull-request"
echo "  Creating credential for pull requests..."
az ad app federated-credential create \
    --id "$CLIENT_ID" \
    --parameters '{
        "name": "'"$CRED_NAME_PR"'",
        "issuer": "https://token.actions.githubusercontent.com",
        "subject": "repo:'"$GITHUB_ORG"'/'"$GITHUB_REPO"':pull_request",
        "audiences": ["api://AzureADTokenExchange"]
    }' 2>/dev/null || echo "    (Credential may already exist)"

# Federated credentials for environments (dev, qua, prod)
for ENV in dev qua prod; do
    CRED_NAME_ENV="github-${ENV}-env"
    echo "  Creating credential for ${ENV} environment..."
    az ad app federated-credential create \
        --id "$CLIENT_ID" \
        --parameters '{
            "name": "'"$CRED_NAME_ENV"'",
            "issuer": "https://token.actions.githubusercontent.com",
            "subject": "repo:'"$GITHUB_ORG"'/'"$GITHUB_REPO"':environment:'"$ENV"'",
            "audiences": ["api://AzureADTokenExchange"]
        }' 2>/dev/null || echo "    (Credential may already exist)"
done

echo -e "${GREEN}  Federated credentials created${NC}"

# =============================================================================
# Output GitHub Secrets
# =============================================================================
echo ""
echo "=============================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "Add these secrets to your GitHub repository:"
echo "(Settings > Secrets and variables > Actions)"
echo ""
echo "┌─────────────────────┬─────────────────────────────────────────┐"
echo "│ Secret Name         │ Value                                   │"
echo "├─────────────────────┼─────────────────────────────────────────┤"
printf "│ %-19s │ %-39s │\n" "ARM_CLIENT_ID" "$CLIENT_ID"
printf "│ %-19s │ %-39s │\n" "ARM_TENANT_ID" "$TENANT_ID"
printf "│ %-19s │ %-39s │\n" "ARM_SUBSCRIPTION_ID" "$SUBSCRIPTION_ID"
echo "└─────────────────────┴─────────────────────────────────────────┘"
echo ""
echo -e "${YELLOW}Note: ARM_CLIENT_SECRET is NOT required with OIDC federation!${NC}"
echo ""
echo "Federated credentials created for:"
echo "  - Push to main branch"
echo "  - Pull requests"
echo "  - Environments: dev, qua, prod"
echo ""
echo "Make sure to update your GitHub Actions workflow to use OIDC:"
echo "  See: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure"

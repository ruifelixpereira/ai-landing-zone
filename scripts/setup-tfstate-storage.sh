#!/bin/bash
# =============================================================================
# Setup Azure Storage Account for Terraform State
# This script creates a storage account with best practices for state management
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
    set -a
    source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
    set +a
fi

# =============================================================================
# Configuration
# =============================================================================
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
LOCATION="${LOCATION:-swedencentral}"
RESOURCE_GROUP_NAME="${TFSTATE_RESOURCE_GROUP:-rg-tfstate}"
STORAGE_ACCOUNT_NAME="${TFSTATE_STORAGE_ACCOUNT:-}"
CONTAINER_NAME="${TFSTATE_CONTAINER:-tfstate}"

# =============================================================================
# Functions
# =============================================================================

print_usage() {
    echo "Usage: $0"
    echo ""
    echo "Configuration can be provided via .env file or environment variables:"
    echo ""
    echo "Required:"
    echo "  SUBSCRIPTION_ID           - Azure Subscription ID"
    echo "  TFSTATE_STORAGE_ACCOUNT   - Storage account name (must be globally unique)"
    echo ""
    echo "Optional:"
    echo "  LOCATION                  - Azure region (default: swedencentral)"
    echo "  TFSTATE_RESOURCE_GROUP    - Resource group name (default: rg-tfstate)"
    echo "  TFSTATE_CONTAINER         - Container name (default: tfstate)"
    echo ""
    echo "Example:"
    echo "  SUBSCRIPTION_ID=xxx TFSTATE_STORAGE_ACCOUNT=stmyorgstate ./setup-tfstate-storage.sh"
}

check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI is not installed${NC}"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        echo -e "${RED}Error: Not logged in to Azure CLI. Run 'az login' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Requirements met.${NC}"
}

validate_inputs() {
    if [[ -z "$SUBSCRIPTION_ID" ]]; then
        echo -e "${RED}Error: SUBSCRIPTION_ID is required${NC}"
        print_usage
        exit 1
    fi
    
    if [[ -z "$TFSTATE_STORAGE_ACCOUNT" ]]; then
        echo -e "${RED}Error: TFSTATE_STORAGE_ACCOUNT is required${NC}"
        print_usage
        exit 1
    fi
    
    # Validate storage account name (3-24 chars, lowercase letters and numbers only)
    if [[ ! "$TFSTATE_STORAGE_ACCOUNT" =~ ^[a-z0-9]{3,24}$ ]]; then
        echo -e "${RED}Error: Storage account name must be 3-24 characters, lowercase letters and numbers only${NC}"
        exit 1
    fi
}

# =============================================================================
# Main Script
# =============================================================================

echo "=============================================="
echo "Terraform State Storage Account Setup"
echo "=============================================="
echo ""

check_requirements
validate_inputs

echo ""
echo "Configuration:"
echo "  Subscription ID:      $SUBSCRIPTION_ID"
echo "  Location:             $LOCATION"
echo "  Resource Group:       $RESOURCE_GROUP_NAME"
echo "  Storage Account:      $TFSTATE_STORAGE_ACCOUNT"
echo "  Container:            $CONTAINER_NAME"
echo ""

# Set subscription
echo -e "${YELLOW}Setting subscription...${NC}"
az account set --subscription "$SUBSCRIPTION_ID"

# =============================================================================
# Create Resource Group
# =============================================================================
echo ""
echo -e "${YELLOW}Creating resource group...${NC}"

az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --only-show-errors || echo "  (Resource group may already exist)"

echo -e "${GREEN}  Resource group ready${NC}"

# =============================================================================
# Create Storage Account
# =============================================================================
echo ""
echo -e "${YELLOW}Creating storage account...${NC}"

az storage account create \
    --name "$TFSTATE_STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --only-show-errors || echo "  (Storage account may already exist)"

echo -e "${GREEN}  Storage account created${NC}"

# =============================================================================
# Enable Soft Delete and Versioning
# =============================================================================
echo ""
echo -e "${YELLOW}Enabling blob soft delete and versioning...${NC}"

az storage account blob-service-properties update \
    --account-name "$TFSTATE_STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-delete-retention true \
    --delete-retention-days 30 \
    --enable-versioning true \
    --enable-container-delete-retention true \
    --container-delete-retention-days 30 \
    --only-show-errors

echo -e "${GREEN}  Soft delete and versioning enabled${NC}"

# =============================================================================
# Create Container
# =============================================================================
echo ""
echo -e "${YELLOW}Creating blob container...${NC}"

az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$TFSTATE_STORAGE_ACCOUNT" \
    --auth-mode login \
    --only-show-errors || echo "  (Container may already exist)"

echo -e "${GREEN}  Container created${NC}"

# =============================================================================
# Grant Access to Service Principal
# =============================================================================
# If GITHUB_SP_CLIENT_ID is not set, try to get it from the app created by setup-github-oidc.sh
if [[ -z "$GITHUB_SP_CLIENT_ID" ]]; then
    APP_NAME="${APP_NAME:-github-ai-landing-zone}"
    echo ""
    echo -e "${YELLOW}Looking up service principal for app: $APP_NAME${NC}"
    GITHUB_SP_CLIENT_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv 2>/dev/null || true)
    
    if [[ -n "$GITHUB_SP_CLIENT_ID" ]]; then
        echo -e "${GREEN}  Found: $GITHUB_SP_CLIENT_ID${NC}"
    else
        echo -e "${YELLOW}  No service principal found with name '$APP_NAME'. Skipping role assignment.${NC}"
        echo -e "${YELLOW}  Run setup-github-oidc.sh first or set GITHUB_SP_CLIENT_ID manually.${NC}"
    fi
fi

if [[ -n "$GITHUB_SP_CLIENT_ID" ]]; then
    echo ""
    echo -e "${YELLOW}Granting Storage Blob Data Contributor role to service principal...${NC}"
    
    STORAGE_ID=$(az storage account show \
        --name "$TFSTATE_STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)
    
    az role assignment create \
        --assignee "$GITHUB_SP_CLIENT_ID" \
        --role "Storage Blob Data Contributor" \
        --scope "$STORAGE_ID" \
        --only-show-errors 2>/dev/null || echo "  (Role may already exist)"
    
    echo -e "${GREEN}  Role assigned to $GITHUB_SP_CLIENT_ID${NC}"
fi

# =============================================================================
# Output Configuration
# =============================================================================
echo ""
echo "=============================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "Add the following backend configuration to your Terraform:"
echo ""
echo "terraform {"
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "    storage_account_name = \"$TFSTATE_STORAGE_ACCOUNT\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"ai-landing-zone/\${environment}.tfstate\""
echo "    use_oidc             = true"
echo "  }"
echo "}"
echo ""
echo "Add these secrets to your GitHub environments:"
echo ""
echo "┌──────────────────────────────┬─────────────────────────────────────────┐"
echo "│ Secret Name                  │ Value                                   │"
echo "├──────────────────────────────┼─────────────────────────────────────────┤"
printf "│ %-28s │ %-39s │\n" "TFSTATE_RESOURCE_GROUP" "$RESOURCE_GROUP_NAME"
printf "│ %-28s │ %-39s │\n" "TFSTATE_STORAGE_ACCOUNT" "$TFSTATE_STORAGE_ACCOUNT"
printf "│ %-28s │ %-39s │\n" "TFSTATE_CONTAINER" "$CONTAINER_NAME"
echo "└──────────────────────────────┴─────────────────────────────────────────┘"
echo ""
echo -e "${YELLOW}Note: The state file key will be set automatically per environment.${NC}"

# AI Landing Zone Terraform

This repository contains Terraform code to deploy the Azure AI Landing Zone, leveraging [Azure Verified Modules](https://aka.ms/avm) (AVM).
Since the AI Landing Zone uses several Private Endpoints, this repository also provides the Azure Policy code that automates the creation of A-records in the corresponding Private DNS Zones and adds DNS forwarding rules for existing private DNS zones.

## Quick Start

- AI Landing Zone: Check the instructions at [AI Landing Zone Module Test](./solutions/ai/README.md)
- Azure Policy for AI Landing Zone: Check the instructions at [Azure Policy Module Test](./solutions/policies/README.md)

## Repository Structure

```
├── .github/workflows/          # GitHub Actions CI/CD pipelines
│   ├── deploy-ai-lz.yml        # Workflow for AI Landing Zone deployment
│   └── deploy-policies.yml     # Workflow for Policies deployment
├── modules/                    # Reusable Terraform modules
│   ├── ai-lz/                  # AI Landing Zone wrapper module
│   ├── apim/                   # API Management configuration
│   ├── dns-resolver-policies/  # DNS forwarding rules and policy
│   └── dns-zone-policies/      # Private DNS zone DINE policies
├── scripts/                    # Setup and utility scripts
│   ├── .env.example            # Sample configuration for OIDC setup
│   └── setup-github-oidc.sh    # Configure Azure OIDC for GitHub Actions
├── solutions/                  # Deployable solutions (root modules)
│   ├── ai/                     # AI Landing Zone deployment
│   └── policies/               # Azure Policies deployment
└── atlantis.yaml               # Atlantis configuration (optional)
```

### Modules vs Solutions

| Folder | Purpose |
|--------|---------|
| `modules/` | Reusable Terraform modules that encapsulate specific functionality. Not deployed directly. |
| `solutions/` | Root modules that compose modules together for deployment. Contains `terraform.tfvars` and backend configuration. |

### Module Descriptions

| Module | Description |
|--------|-------------|
| `ai-lz` | Wrapper around the AVM AI/ML Landing Zone pattern module with feature flags and customizations |
| `apim` | API Management instance configuration for AI Gateway pattern |
| `dns-resolver-policies` | Creates DNS forwarding rules for private DNS zones + optional DINE policy |
| `dns-zone-policies` | DINE policies for automatic Private Endpoint DNS zone group configuration |

## GitHub Actions CI/CD

This repository includes two GitHub Actions workflows for automated Terraform deployments:

| Workflow | File | Deploys |
|----------|------|---------|
| Deploy AI Landing Zone | `.github/workflows/deploy-ai-lz.yml` | `solutions/ai/` |
| Deploy Policies | `.github/workflows/deploy-policies.yml` | `solutions/policies/` |

### Required Secrets

Configure the following secrets in your GitHub repository using environments (**Settings > Secrets and variables > Actions**):

| Secret | Description |
|--------|-------------|
| `ARM_CLIENT_ID` | Azure Service Principal Application (client) ID |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID for deployment |
| `ARM_TENANT_ID` | Azure AD Tenant ID |

> **Note:** `ARM_CLIENT_SECRET` is NOT required when using OIDC federation (recommended).

#### Setting up OIDC Federation (Recommended)

OIDC federation eliminates the need for storing client secrets. 

**Option 1: Using .env file (recommended)**

```bash
# Copy the example file and edit with your values
cp scripts/.env.example scripts/.env

# Edit the configuration
# Required: GITHUB_ORG, GITHUB_REPO, SUBSCRIPTION_ID
vim scripts/.env

# Run the script
./scripts/setup-github-oidc.sh
```

**Option 2: Using environment variables**

```bash
GITHUB_ORG=myorg \
GITHUB_REPO=ai-landing-zone \
SUBSCRIPTION_ID=your-subscription-id \
./scripts/setup-github-oidc.sh
```

The script will:
1. Create an Azure AD Application and Service Principal
2. Assign Contributor and User Access Administrator roles
3. Create federated credentials for:
   - Push to main branch
   - Pull requests
   - Environments: dev, qua, prod
4. Output the secrets to configure in GitHub

#### Creating a Service Principal (Alternative - with secret)

```bash
# Create a service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-ai-landing-zone" \
  --role "Contributor" \
  --scopes "/subscriptions/<subscription-id>" \
  --sdk-auth

# For policy assignments, you may also need Owner or User Access Administrator
az role assignment create \
  --assignee "<client-id>" \
  --role "User Access Administrator" \
  --scope "/subscriptions/<subscription-id>"
```

### Workflow Triggers

Both workflows support three trigger types:

| Trigger | Behavior |
|---------|----------|
| **Push to main** | Auto-runs `validate` → `apply` (dev environment) when files in the relevant paths change |
| **Pull Request** | Auto-runs `validate` → `plan` and uploads plan as artifact |
| **Manual (workflow_dispatch)** | Choose environment (`dev`/`qua`/`prod`) and action (`plan`/`apply`/`destroy`) |

### Path Filters

Workflows only trigger when relevant files change:

- **AI Landing Zone**: `solutions/ai/**`, `modules/ai-lz/**`, `modules/apim/**`
- **Policies**: `solutions/policies/**`, `modules/private-dns-zone-policies/**`, `modules/private-dns-resolver-policies/**`

### Manual Deployment

To run a workflow manually:

1. Go to **Actions** tab in GitHub
2. Select the workflow (e.g., "Deploy AI Landing Zone")
3. Click **Run workflow**
4. Select the **environment**: `dev`, `qua`, or `prod`
5. Select the **action**: `plan`, `apply`, or `destroy`
6. Click **Run workflow**

The selected environment is passed to Terraform as `TF_VAR_environment`, which can be used to customize resource naming, SKUs, and other environment-specific settings.

### Environment Protection (Recommended)

Workflows use GitHub environments for deployment protection. Create three environments:

1. Go to **Settings > Environments**
2. Create environments: `dev`, `qua`, `prod`
3. Configure protection rules per environment:

| Environment | Recommended Protection |
|-------------|------------------------|
| `dev` | No protection (fast iteration) |
| `qua` | Optional: Wait timer (e.g., 5 minutes) |
| `prod` | Required reviewers, deployment branches restricted to `main` |

Example `prod` configuration:
- **Required reviewers**: Add team members who must approve deployments
- **Wait timer**: Optional delay before deployment starts
- **Deployment branches**: Select "Selected branches" → Add `main`

### Workflow Jobs

| Job | Description | When |
|-----|-------------|------|
| `validate` | Format check, init, validate | Always |
| `plan` | Generate and upload plan | PRs, manual plan |
| `apply` | Apply changes to selected environment | Push to main, manual apply |
| `destroy` | Destroy resources in selected environment | Manual destroy only |

> **Note:** Job names include the target environment (e.g., "Apply (prod)") for visibility.

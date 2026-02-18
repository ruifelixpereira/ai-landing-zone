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
│   ├── .env.example            # Sample configuration for setup scripts
│   ├── setup-github-oidc.sh    # Configure Azure OIDC for GitHub Actions
│   └── setup-tfstate-storage.sh # Create Azure Storage for Terraform state
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

### Prerequisites Setup

Before configuring GitHub environments, run the setup scripts to create the required Azure resources.

#### 1. Setting up OIDC Federation (Recommended)

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

**Alternative: Creating a Service Principal with secret**

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

#### 2. Setting up Terraform State Storage

Terraform state is stored remotely in Azure Storage with one state file per environment. Run the provided script to create the storage account:

```bash
# Edit scripts/.env with your values (TFSTATE_STORAGE_ACCOUNT is required)
vim scripts/.env

# Run the script
./scripts/setup-tfstate-storage.sh
```

The script will:
1. Create a resource group for state storage
2. Create a storage account with:
   - Soft delete enabled (30 days retention)
   - Versioning enabled for recovery
   - Public access disabled
3. Create a blob container for state files
4. Optionally grant Storage Blob Data Contributor to your service principal

**State file organization:**
```
tfstate/
├── ai-landing-zone/dev.tfstate
├── ai-landing-zone/qua.tfstate
├── ai-landing-zone/prod.tfstate
├── policies/dev.tfstate
├── policies/qua.tfstate
└── policies/prod.tfstate
```

### GitHub Environments Setup

This repository uses GitHub environments for deployment protection and environment-specific secrets. **You must create the environments before running any workflow.**

#### Creating Environments

1. Go to **Settings > Environments**
2. Create three environments: `dev`, `qua`, `prod`
3. For each environment, add the required secrets (see below)

#### Required Secrets (Per Environment)

Secrets must be created at the **environment level**, not the repository level. For each environment (`dev`, `qua`, `prod`):

1. Go to **Settings > Environments > [environment name]**
2. Click **Add secret** and create the following:

| Secret | Description |
|--------|-------------|
| `ARM_CLIENT_ID` | Azure Service Principal Application (client) ID |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID for this environment |
| `ARM_TENANT_ID` | Azure AD Tenant ID |
| `TFSTATE_RESOURCE_GROUP` | Resource group containing the state storage account |
| `TFSTATE_STORAGE_ACCOUNT` | Storage account name for Terraform state |
| `TFSTATE_CONTAINER` | Blob container name for state files |
| `TFVARS` | (Optional) Terraform variables in HCL format |

> **Note:** `ARM_CLIENT_SECRET` is NOT required when using OIDC federation (recommended).

This allows you to:
- Deploy to different Azure subscriptions per environment
- Use different Terraform configurations per environment
- Use separate Service Principals with appropriate permissions

#### Using TFVARS Secret

Instead of committing `terraform.tfvars` to the repository, store your Terraform variables as a GitHub secret at the environment level. The workflow will automatically create `terraform.tfvars` from this secret if it's defined.

**Setting up TFVARS for each environment:**

1. Go to **Settings > Environments > [environment name]** (e.g., `dev`)
2. Click **Add secret**
3. Name: `TFVARS`
4. Value: Paste your variables in HCL format:

```hcl
ai_resource_group_name         = "rg-ai-dev"
networking_resource_group_name = "rg-ai-networking-dev"
location                       = "Sweden Central"
vnet_name                      = "ai-lz-vnet-dev"
vnet_address_space             = "192.168.0.0/23"
enable_telemetry               = false
enabled_features               = ["apim"]

tags = {
  environment = "dev"
  project     = "ai-platform"
}
```

Repeat for `qua` and `prod` environments with appropriate values (different resource groups, VNet address spaces, etc.).

### Environment Protection (Recommended)

Configure protection rules for each environment:

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

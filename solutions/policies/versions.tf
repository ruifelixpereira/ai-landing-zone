terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0"
    }
  }

  # Configure remote state in Azure Storage
  # Backend values are passed via -backend-config in CI/CD
  # Or uncomment and hardcode values for local development
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
    # resource_group_name  = "rg-tfstate"
    # storage_account_name = "stterraformstate"
    # container_name       = "tfstate"
    # key                  = "policies/dev.tfstate"
  }
}


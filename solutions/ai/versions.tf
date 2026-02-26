terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.8"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Configure remote state in Azure Storage
  # Backend values are passed via -backend-config in CI/CD
  # Or uncomment and hardcode values for local development
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
    resource_group_name  = "rg-tfstate"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "ai-landing-zone/dev.tfstate"
  }
}

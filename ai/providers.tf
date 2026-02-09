provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
  storage_use_azuread = true

  # Authentication options:
  # - Azure CLI: az login
  # - Service Principal: Set ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
  # - Managed Identity: When running in Azure
  # subscription_id = var.subscription_id
}

provider "azapi" {
  # Uses the same authentication as azurerm
}

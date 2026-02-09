
locals {
  # Extract resource group name from resource ID
  # Format: /subscriptions/{sub-id}/resourceGroups/{rg-name}
  dns_zones_resource_group_name = element(split("/", var.dns_zones_resource_group_id), 4)
}

# Gather your existing private DNS zone IDs from the platform landing zone
data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "cognitiveservices" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "aiservices" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "apim" {
  name                = "privatelink.azure-api.net"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "cosmos_sql" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "containerregistry" {
  name                = "privatelink.azurecr.io"
  resource_group_name = local.dns_zones_resource_group_name
}

data "azurerm_private_dns_zone" "appconfig" {
  name                = "privatelink.azconfig.io"
  resource_group_name = local.dns_zones_resource_group_name
}

# Then use the module
module "private_dns_policies" {
  source = "../modules/private-dns-zone-policies"

  management_group_id         = var.management_group_id
  assignment_scope            = var.management_group_id
  location                    = var.location
  dns_zones_resource_group_id = var.dns_zones_resource_group_id

  private_dns_zone_ids = {
    "privatelink.blob.core.windows.net"       = data.azurerm_private_dns_zone.blob.id
    "privatelink.queue.core.windows.net"      = data.azurerm_private_dns_zone.queue.id
    "privatelink.table.core.windows.net"      = data.azurerm_private_dns_zone.table.id
    "privatelink.file.core.windows.net"       = data.azurerm_private_dns_zone.file.id
    "privatelink.dfs.core.windows.net"        = data.azurerm_private_dns_zone.dfs.id
    "privatelink.vaultcore.azure.net"         = data.azurerm_private_dns_zone.keyvault.id
    "privatelink.openai.azure.com"            = data.azurerm_private_dns_zone.openai.id
    "privatelink.cognitiveservices.azure.com" = data.azurerm_private_dns_zone.cognitiveservices.id
    "privatelink.services.ai.azure.com"       = data.azurerm_private_dns_zone.aiservices.id
    "privatelink.search.windows.net"          = data.azurerm_private_dns_zone.search.id
    "privatelink.azure-api.net"               = data.azurerm_private_dns_zone.apim.id
    "privatelink.documents.azure.com"         = data.azurerm_private_dns_zone.cosmos_sql.id
    "privatelink.azurecr.io"                  = data.azurerm_private_dns_zone.containerregistry.id
    "privatelink.azconfig.io"                 = data.azurerm_private_dns_zone.appconfig.id
    # Add more as needed...
  }
}

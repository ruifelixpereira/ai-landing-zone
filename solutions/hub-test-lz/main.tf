resource "azurerm_resource_group" "hub" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = var.vnet_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = var.private_dns_zone_names
  name                = each.value
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

output "resource_group_id" {
  description = "Resource ID of the created hub resource group."
  value       = azurerm_resource_group.hub.id
}

output "vnet_id" {
  description = "Resource ID of the created hub virtual network."
  value       = azurerm_virtual_network.hub.id
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to their resource IDs."
  value = {
    for zone_name, zone in azurerm_private_dns_zone.this : zone_name => zone.id
  }
}

output "private_dns_zone_names" {
  description = "List of created private DNS zone names."
  value       = sort(keys(azurerm_private_dns_zone.this))
}

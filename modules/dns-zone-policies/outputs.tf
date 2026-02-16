output "policy_definition_ids" {
  description = "Map of policy definition IDs for each private link type"
  value = {
    for key, definition in azurerm_policy_definition.private_dns_zone_link :
    key => definition.id
  }
}

output "policy_initiative_id" {
  description = "The ID of the policy initiative (policy set definition)"
  value       = length(azurerm_policy_set_definition.private_dns_zone_initiative) > 0 ? azurerm_policy_set_definition.private_dns_zone_initiative[0].id : null
}

output "policy_assignment_id" {
  description = "The ID of the policy assignment"
  value       = length(azurerm_management_group_policy_assignment.private_dns_zone_assignment) > 0 ? azurerm_management_group_policy_assignment.private_dns_zone_assignment[0].id : null
}

output "policy_identity_principal_id" {
  description = "The principal ID of the policy assignment's managed identity"
  value       = length(azurerm_management_group_policy_assignment.private_dns_zone_assignment) > 0 ? azurerm_management_group_policy_assignment.private_dns_zone_assignment[0].identity[0].principal_id : null
}

output "enabled_policies" {
  description = "List of enabled policy types based on provided DNS zone IDs"
  value       = keys(local.enabled_policies)
}

output "forwarding_rules" {
  description = "Map of created DNS forwarding rules"
  value = {
    for name, rule in azurerm_private_dns_resolver_forwarding_rule.rules :
    name => {
      id          = rule.id
      name        = rule.name
      domain_name = rule.domain_name
      enabled     = rule.enabled
    }
  }
}

output "target_dns_servers" {
  description = "The target DNS servers used for forwarding rules"
  value       = local.target_dns_servers
}

output "inbound_endpoint_ip" {
  description = "The inbound endpoint IP resolved from the endpoint name (if provided)"
  value       = local.inbound_endpoint_ip
}

output "processed_dns_zones" {
  description = "List of DNS zones that were processed"
  value       = keys(local.dns_zones_to_process)
}

output "excluded_dns_zones" {
  description = "List of DNS zones that were excluded"
  value       = var.exclude_zones
}

output "policy_definition_id" {
  description = "ID of the DNS forwarding rule policy definition (if created)"
  value       = var.create_policy ? azurerm_policy_definition.dns_forwarding_rule[0].id : null
}

output "policy_assignment_id" {
  description = "ID of the DNS forwarding rule policy assignment (if created)"
  value       = var.create_policy ? azurerm_management_group_policy_assignment.dns_forwarding_rule[0].id : null
}

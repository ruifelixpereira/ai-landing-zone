output "policy_initiative_id" {
  description = "The ID of the policy initiative (policy set definition)"
  value       = module.private_dns_policies.policy_initiative_id
}

output "enabled_policies" {
  description = "List of enabled policy types based on provided DNS zone IDs"
  value       = module.private_dns_policies.enabled_policies
}


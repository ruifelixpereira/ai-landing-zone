output "subnets" {
  description = "A map of the deployed subnets in the AI PTN LZA."
  value       = module.vnet.resource_id
}
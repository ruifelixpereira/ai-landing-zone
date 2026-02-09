output "subnets" {
  description = "A map of the deployed subnets in the AI PTN LZA."
  value       = module.ai_landing_zone.subnets
}
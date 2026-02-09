# AI Landing Zone Module Test
# This configuration calls the ai-lz module for testing purposes

module "ai_landing_zone" {
  source = "../modules/ai-lz"
  ai_resource_group_name = var.ai_resource_group_name
  networking_resource_group_name = var.networking_resource_group_name
  location            = var.location
  environment         = var.environment
  enable_telemetry = var.enable_telemetry
  vnet_name = var.vnet_name
  vnet_address_space = var.vnet_address_space
  existing_zones_resource_group_resource_id = var.existing_zones_resource_group_resource_id
  existing_hub_firewall_ip_address = var.existing_hub_firewall_ip_address
  existing_hub_virtual_network_resource_id = var.existing_hub_virtual_network_resource_id
  tags = var.tags

  # Feature Flags
  enabled_features = var.enabled_features
}

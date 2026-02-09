module "apim" {
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = "0.0.6"
  count   = var.apim_definition.deploy ? 1 : 0

  location                   = var.location
  name                       = var.apim_definition.name
  publisher_email            = var.apim_definition.publisher_email
  resource_group_name        = var.resource_group_name
  additional_location        = var.apim_definition.additional_locations
  certificate                = var.apim_definition.certificate
  client_certificate_enabled = var.apim_definition.client_certificate_enabled
  diagnostic_settings        = var.apim_definition.diagnostic_settings
  enable_telemetry           = var.enable_telemetry
  hostname_configuration     = var.apim_definition.hostname_configuration
  managed_identities         = var.apim_definition.managed_identities
  min_api_version            = var.apim_definition.min_api_version
  notification_sender_email  = var.apim_definition.notification_sender_email
  private_endpoints = {
    endpoint1 = {
      #private_dns_zone_resource_ids = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : (var.flag_platform_landing_zone ? [module.private_dns_zones.apim_zone.resource_id] : [local.private_dns_zones_existing.apim_zone.resource_id])
      subnet_resource_id     = var.network_configuration.private_endpoint_subnet_id
    }
  }
  protocols                     = var.apim_definition.protocols
  public_network_access_enabled = true
  publisher_name                = var.apim_definition.publisher_name
  role_assignments              = local.apim_role_assignments
  sign_in                       = var.apim_definition.sign_in
  sign_up                       = var.apim_definition.sign_up
  sku_name                      = "${var.apim_definition.sku_root}_${var.apim_definition.sku_capacity}"
  tags                          = var.apim_definition.tags
  tenant_access                 = var.apim_definition.tenant_access
  virtual_network_subnet_id     = var.network_configuration.virtual_network_subnet_id
  virtual_network_type          = var.network_configuration.virtual_network_type
  zones                         = var.zones
}
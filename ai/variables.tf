variable "ai_resource_group_name" {
  description = "Name of the resource group for AI infrastructure"
  type        = string
}

variable "networking_resource_group_name" {
  description = "Name of the resource group for AI Networking infrastructure"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Sweden Central"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "vnet_name" {
  type        = string
  default     = "ai-lz-vnet-01"
  description = "The name of the AI spoke Virtual Network."
}

variable "vnet_address_space" {
  type        = string
  default     = "192.168.0.0/23"
  description = "The address space for the AI spoke Virtual Network. Must be within 192.168.0.0/16 for AI Foundry capabilityHost injection."
}

variable "existing_zones_resource_group_resource_id" {
  type        = string
  description = "The name of the existing Resource group in the Platform LZ Hub where the Private DNS Zones reside."
}

variable "existing_hub_virtual_network_resource_id" {
  type        = string
  description = "The ID of the existing Hub virtual network."
}

variable "existing_hub_firewall_ip_address" {
  type        = string
  description = "The IP address of the existing Hub firewall."
}

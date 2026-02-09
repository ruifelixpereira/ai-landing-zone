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
  description = "Environment name (dev, qua, or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qua", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qua, or prod."
  }
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
  description = "The name of the Virtual Network."
}

variable "vnet_address_space" {
  type        = string
  default     = "192.168.0.0/23"
  description = "The address space for the Virtual Network. Must be within 192.168.0.0/16 for AI Foundry capabilityHost injection."
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

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

# ==========================================
# Feature Flags
# ==========================================

variable "enabled_features" {
  type        = set(string)
  default     = ["container_app_environment", "container_registry", "genai_cosmosdb", "genai_keyvault", "genai_storage_account", "genai_app_configuration", "ai_search", "bing_grounding"]
  description = <<DESCRIPTION
Set of features to enable. Valid values:
- apim: Azure API Management
- app_gateway: Azure Application Gateway
- bastion: Azure Bastion
- container_app_environment: Azure Container App Environment
- container_registry: Azure Container Registry for GenAI
- genai_cosmosdb: Azure Cosmos DB for GenAI
- genai_storage_account: Azure Storage Account for GenAI
- genai_keyvault: Azure Key Vault for GenAI
- genai_app_configuration: Azure App Configuration for GenAI
- ai_search: Azure AI Search for knowledge store
- bing_grounding: Bing Grounding service
- build_vm: Build VM
- jump_vm: Jump VM
DESCRIPTION

  validation {
    condition = alltrue([
      for f in var.enabled_features : contains([
        "apim", "app_gateway", "bastion", "container_app_environment",
        "container_registry", "genai_cosmosdb", "genai_storage_account",
        "genai_keyvault", "genai_app_configuration", "ai_search", "bing_grounding",
        "build_vm", "jump_vm"
      ], f)
    ])
    error_message = "Invalid feature name. See variable description for valid values."
  }
}
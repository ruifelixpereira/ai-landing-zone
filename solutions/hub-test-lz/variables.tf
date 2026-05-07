variable "location" {
  description = "Azure region where the hub resources are deployed."
  type        = string
  default     = "Sweden Central"
}

variable "resource_group_name" {
  description = "Name of the hub resource group."
  type        = string
}

variable "vnet_name" {
  description = "Name of the hub virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the hub vnet."
  type        = list(string)
  default     = ["10.0.0.0/20"]
}

variable "private_dns_zone_names" {
  description = "Set of private DNS zone names to create in the hub resource group."
  type        = set(string)
  default = [
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.search.windows.net"
  ]

  validation {
    condition = length(var.private_dns_zone_names) > 0 && alltrue([
      for zone_name in var.private_dns_zone_names : length(trimspace(zone_name)) > 0
    ])
    error_message = "private_dns_zone_names must contain at least one non-empty zone name."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

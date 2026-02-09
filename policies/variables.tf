variable "location" {
  type        = string
  description = "Azure region for the policy assignment's managed identity."
}

variable "management_group_id" {
  type        = string
  description = "The management group ID where the policy definitions will be created."
}

variable "dns_zones_resource_group_id" {
  type        = string
  description = "The resource ID of the resource group containing the private DNS zones. Used for role assignment."
}


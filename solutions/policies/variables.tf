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

variable "dns_forwarding_ruleset_resource_id" {
  type        = string
  description = "Resource ID of the DNS Forwarding Ruleset to add rules to."
}

variable "dns_resolver_resource_id" {
  type        = string
  default     = null
  description = "Resource ID of the Private DNS Resolver. Required if target_dns_servers is not provided."
}

variable "dns_resolver_inbound_endpoint_name" {
  type        = string
  default     = null
  description = "Name of the Private DNS Resolver inbound endpoint. Required if target_dns_servers is not provided."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources."
}
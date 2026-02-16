variable "dns_zones_resource_group_name" {
  type        = string
  description = "Name of the resource group containing the private DNS zones."
}

variable "dns_forwarding_ruleset_resource_id" {
  type        = string
  description = "Resource ID of the DNS Forwarding Ruleset to add rules to."
}

variable "target_dns_servers" {
  type = list(object({
    ip_address = string
    port       = optional(number, 53)
  }))
  default     = null
  description = "List of target DNS servers to forward queries to. If null, uses the inbound endpoint IP from the dns_resolver configuration."
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

variable "rule_state" {
  type        = string
  default     = "Enabled"
  description = "State of the forwarding rules. Can be 'Enabled' or 'Disabled'."

  validation {
    condition     = contains(["Enabled", "Disabled"], var.rule_state)
    error_message = "rule_state must be either 'Enabled' or 'Disabled'."
  }
}

variable "exclude_zones" {
  type        = set(string)
  default     = []
  description = "Set of DNS zone names to exclude from rule creation."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources."
}

# Policy-related variables
variable "create_policy" {
  type        = bool
  default     = false
  description = "Whether to create an Azure Policy for VNet link enforcement."
}

variable "management_group_id" {
  type        = string
  default     = null
  description = "Management group ID for policy definition scope. Required if create_policy is true."
}

variable "policy_assignment_scope" {
  type        = string
  default     = null
  description = "Scope for policy assignment. If null, uses management_group_id."
}

variable "location" {
  type        = string
  default     = "swedencentral"
  description = "Location for policy assignment managed identity."
}

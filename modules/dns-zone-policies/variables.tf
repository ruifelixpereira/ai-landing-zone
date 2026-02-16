variable "management_group_id" {
  type        = string
  description = "The management group ID where the policy definitions will be created."
}

variable "assignment_scope" {
  type        = string
  default     = null
  description = "The scope at which to assign the policy. Defaults to the management_group_id if not specified."
}

variable "location" {
  type        = string
  description = "Azure region for the policy assignment's managed identity."
}

variable "private_dns_zone_ids" {
  type        = map(string)
  description = <<DESCRIPTION
Map of private DNS zone names to their resource IDs.
The key should be the DNS zone name (e.g., "privatelink.blob.core.windows.net")
and the value should be the full resource ID.

Example:
{
  "privatelink.blob.core.windows.net"           = "/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net"
  "privatelink.vaultcore.azure.net"             = "/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net"
  "privatelink.database.windows.net"            = "/subscriptions/.../privateDnsZones/privatelink.database.windows.net"
  "privatelink.documents.azure.com"             = "/subscriptions/.../privateDnsZones/privatelink.documents.azure.com"
  "privatelink.azurecr.io"                      = "/subscriptions/.../privateDnsZones/privatelink.azurecr.io"
  "privatelink.cognitiveservices.azure.com"     = "/subscriptions/.../privateDnsZones/privatelink.cognitiveservices.azure.com"
  "privatelink.openai.azure.com"                = "/subscriptions/.../privateDnsZones/privatelink.openai.azure.com"
  "privatelink.api.azureml.ms"                  = "/subscriptions/.../privateDnsZones/privatelink.api.azureml.ms"
  "privatelink.search.windows.net"              = "/subscriptions/.../privateDnsZones/privatelink.search.windows.net"
}
DESCRIPTION
}

variable "dns_zones_resource_group_id" {
  type        = string
  description = "The resource ID of the resource group containing the private DNS zones. Used for role assignment."
}

variable "create_assignment" {
  type        = bool
  default     = true
  description = "Whether to create the policy assignment. Set to false if you only want to create the definitions."
}

variable "policy_effect" {
  type        = string
  default     = "DeployIfNotExists"
  description = "The effect of the policy. Can be 'DeployIfNotExists' or 'Disabled'."

  validation {
    condition     = contains(["DeployIfNotExists", "Disabled"], var.policy_effect)
    error_message = "Policy effect must be either 'DeployIfNotExists' or 'Disabled'."
  }
}

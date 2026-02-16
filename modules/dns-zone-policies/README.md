# Azure Policy for Private DNS Zone Linking

This module creates Azure Policy definitions that automatically configure private endpoints to use centralized private DNS zones. This is essential for Platform Landing Zone architectures where private DNS zones are managed centrally.

## Overview

When private endpoints are created in spoke subscriptions, this policy uses the **DeployIfNotExists** (DINE) effect to automatically create a `privateDnsZoneGroup` that links the private endpoint to the appropriate central private DNS zone.

## Supported Services

The module supports the following Azure services:

| Service | Group ID | DNS Zone |
|---------|----------|----------|
| Storage Blob | blob | privatelink.blob.core.windows.net |
| Storage Table | table | privatelink.table.core.windows.net |
| Storage Queue | queue | privatelink.queue.core.windows.net |
| Storage File | file | privatelink.file.core.windows.net |
| Storage Data Lake | dfs | privatelink.dfs.core.windows.net |
| Key Vault | vault | privatelink.vaultcore.azure.net |
| Azure SQL | sqlServer | privatelink.database.windows.net |
| Cosmos DB (SQL) | Sql | privatelink.documents.azure.com |
| Container Registry | registry | privatelink.azurecr.io |
| Cognitive Services | account | privatelink.cognitiveservices.azure.com |
| Azure OpenAI | account | privatelink.openai.azure.com |
| Azure ML / AI Foundry | amlworkspace | privatelink.api.azureml.ms |
| Azure Search | searchService | privatelink.search.windows.net |
| App Configuration | configurationStores | privatelink.azconfig.io |
| Event Hub / Service Bus | namespace | privatelink.servicebus.windows.net |
| Web Apps / Functions | sites | privatelink.azurewebsites.net |

## Usage

```hcl
# First, gather your existing private DNS zone IDs from the platform landing zone
data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "rg-dns-zones"
}

data "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-dns-zones"
}

data "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = "rg-dns-zones"
}

# Then use the module
module "private_dns_policies" {
  source = "../modules/private-dns-zone-policies"

  management_group_id         = "/providers/Microsoft.Management/managementGroups/mg-landing-zones"
  assignment_scope            = "/providers/Microsoft.Management/managementGroups/mg-landing-zones"
  location                    = "swedencentral"
  dns_zones_resource_group_id = "/subscriptions/xxxx/resourceGroups/rg-dns-zones"

  private_dns_zone_ids = {
    "privatelink.blob.core.windows.net"       = data.azurerm_private_dns_zone.blob.id
    "privatelink.vaultcore.azure.net"         = data.azurerm_private_dns_zone.keyvault.id
    "privatelink.openai.azure.com"            = data.azurerm_private_dns_zone.openai.id
    # Add more as needed...
  }
}
```

## How It Works

1. **Policy Definitions**: The module creates a policy definition for each private link service type you provide DNS zones for.

2. **Policy Initiative**: All individual policies are grouped into a single initiative (policy set definition) for easier management.

3. **Policy Assignment**: The initiative is assigned at the specified scope (management group) with a system-assigned managed identity.

4. **Role Assignments**: The policy's managed identity is granted:
   - `Network Contributor` on the assignment scope (to create DNS zone groups)
   - `Private DNS Zone Contributor` on the DNS zones resource group

5. **Automatic Remediation**: When a private endpoint is created, the policy automatically deploys a `privateDnsZoneGroup` resource that links the endpoint to the central DNS zone.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| management_group_id | Management group ID for policy definitions | string | yes |
| assignment_scope | Scope for policy assignment | string | no |
| location | Azure region for managed identity | string | yes |
| private_dns_zone_ids | Map of DNS zone names to resource IDs | map(string) | yes |
| dns_zones_resource_group_id | Resource group ID containing DNS zones | string | yes |
| create_assignment | Whether to create the assignment | bool | no |
| policy_effect | DeployIfNotExists or Disabled | string | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_definition_ids | Map of policy definition IDs |
| policy_initiative_id | Initiative ID |
| policy_assignment_id | Assignment ID |
| policy_identity_principal_id | Managed identity principal ID |
| enabled_policies | List of enabled policy types |

## Notes

- Only policies for DNS zones you provide will be created
- The policy uses `DeployIfNotExists` which is idempotent
- Existing private endpoints can be remediated using Azure Policy remediation tasks
- The managed identity needs time to propagate after creation (Azure RBAC eventual consistency)

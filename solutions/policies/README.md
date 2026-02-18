# Azure Policies for Private DNS

This directory contains configuration for two modules that help manage private DNS in Platform Landing Zone architectures:

1. **`private-dns-zone-policies`** - Creates Azure Policy definitions that automatically configure private endpoints to use centralized private DNS zones (DINE policies for Private Endpoint DNS Zone Groups).

2. **`dns-resolver-policies`** - Creates DNS forwarding rules for all private DNS zones in a resource group, and optionally an Azure Policy to auto-create forwarding rules when new DNS zones are created.

## Overview

These modules are essential for hub-spoke architectures where:
- Private DNS zones are managed centrally in a Platform Landing Zone
- A Private DNS Resolver provides cross-VNet DNS resolution
- Private endpoints need automatic DNS configuration

## Prerequisites

- Terraform >= 1.9
- Azure CLI installed and authenticated (`az login`)
- Sufficient permissions to create resources in Azure

## Usage

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Inputs

### Private DNS Zone Policies

| Name | Description | Type | Example |
|------|-------------|------|---------|
| location                    | The Azure region for resource deployment | string | "SwedenCentral" |
| management_group_id         | The management group ID for policy assignment | string | "/providers/Microsoft.Management/managementGroups/all_subscriptions" |
| dns_zones_resource_group_id | The resource group ID containing the DNS zones | string | "/subscriptions/111111-111-111-111/resourceGroups/rg-plat-lz-2" |

### DNS Resolver Policies

| Name | Description | Type | Required |
|------|-------------|------|----------|
| dns_zones_resource_group_name | Name of the resource group containing private DNS zones | string | Yes |
| dns_forwarding_ruleset_resource_id | Resource ID of the DNS Forwarding Ruleset | string | Yes |
| dns_resolver_resource_id | Resource ID of the Private DNS Resolver | string | If target_dns_servers not provided |
| dns_resolver_inbound_endpoint_name | Name of the inbound endpoint | string | If target_dns_servers not provided |
| target_dns_servers | List of target DNS servers (ip_address, port) | list(object) | If resolver not provided |
| rule_state | State of forwarding rules: "Enabled" or "Disabled" | string | No (default: "Enabled") |
| exclude_zones | Set of DNS zone names to exclude | set(string) | No |
| create_policy | Whether to create the DINE policy | bool | No (default: false) |
| management_group_id | Management group ID for policy scope | string | If create_policy = true |
| policy_assignment_scope | Scope for policy assignment | string | No |
| location | Location for policy managed identity | string | No (default: "swedencentral") |

## Outputs

### Private DNS Zone Policies

| Name | Description |
|------|-------------|
| policy_initiative_id | The ID of the policy initiative (policy set definition) |
| enabled_policies | List of enabled policy types based on provided DNS zone IDs |

### DNS Resolver Policies

| Name | Description |
|------|-------------|
| forwarding_rules | Map of created DNS forwarding rules |
| inbound_endpoint_ip | IP address of the DNS Resolver inbound endpoint |
| policy_definition_id | ID of the created policy definition (if create_policy = true) |
| policy_assignment_id | ID of the policy assignment (if create_policy = true) |


## Cleanup

To destroy the resources:
```bash
terraform destroy
```

## Example: DNS Resolver Policies Module

```hcl
module "dns_resolver_policies" {
  source = "../../modules/dns-resolver-policies"

  dns_zones_resource_group_name      = "rg-plat-lz"
  dns_forwarding_ruleset_resource_id = "/subscriptions/.../resourceGroups/rg-plat-lz/providers/Microsoft.Network/dnsForwardingRulesets/my-ruleset"
  dns_resolver_resource_id           = "/subscriptions/.../resourceGroups/rg-plat-lz/providers/Microsoft.Network/dnsResolvers/my-resolver"
  dns_resolver_inbound_endpoint_name = "inbound-endpoint"

  # Optional: exclude specific zones
  exclude_zones = ["contoso.local"]

  # Optional: create DINE policy for auto-creating rules
  create_policy       = true
  management_group_id = "/providers/Microsoft.Management/managementGroups/all_subscriptions"
}
```

## Trigger Policy Scan

You can use the following commands to trigger a policy evaluation after deployment:

```bash
# Trigger evaluation for a subscription
az policy state trigger-scan --subscription "your-subscription-id"

# Trigger evaluation for a specific resource group
az policy state trigger-scan --resource-group "your-rg-name"

# Check scan status (returns immediately, scan runs async)
az policy state list --subscription "your-subscription-id"
```

Note: Evaluation scans can take 15-30 minutes even when triggered manually. DINE policies also require a remediation task to apply changes to existing resources - they only auto-apply on new resource creation.

For DeployIfNotExists (DINE) policies to remediate:

```bash
# Trigger remediation for a specific policy assignment

# Create a remediation task to apply the policy
az policy remediation create \
  --name "remediate-dns-zones" \
  --policy-assignment "/subscriptions/{sub}/providers/Microsoft.Authorization/policyAssignments/pe-dns-zone-assign" \
  --resource-group "your-rg-name"

# Or for all non-compliant resources in subscription
az policy remediation create \
  --name "remediate-dns-zones" \
  --policy-assignment "/subscriptions/{sub}/providers/Microsoft.Authorization/policyAssignments/pe-dns-zone-assign"
```

If the policy assignment is an initiative (policy set), so you must specify which policy definition within the set to remediate using --definition-reference-id.

First, list the policy definitions in your initiative:

```bash
az policy set-definition show \
  --name "pe-dns-zone-initiative" \
  --management-group "all_subscriptions" \
  --query "policyDefinitions[].policyDefinitionReferenceId" \
  -o table
```

Then remediate a specific policy:

```bash
az policy remediation create \
  --name "remediate-dns-blob" \
  --policy-assignment "/providers/microsoft.management/managementgroups/all_subscriptions/providers/microsoft.authorization/policyassignments/pe-dns-zone-assign" \
  --definition-reference-id "blob" \
  --resource-group "rg-ai-core-7"
```

To remediate all policies in the initiative, create a remediation for each:

```bash
# Loop through all reference IDs
for ref in blob vault sqlServer registry account searchService configurationStores; do
  az policy remediation create \
    --name "remediate-dns-$ref" \
    --policy-assignment "/providers/microsoft.management/managementgroups/all_subscriptions/providers/microsoft.authorization/policyassignments/pe-dns-zone-assign" \
    --definition-reference-id "$ref" \
    --resource-group "rg-ai-core-7"
done
```

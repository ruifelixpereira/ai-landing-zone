# Azure Policy for Private DNS Zone Linking

This directory contains the test configuration for the `private-dns-zone-policies` module. This module creates Azure Policy definitions that automatically configure private endpoints to use centralized private DNS zones. This is essential for Platform Landing Zone architectures where private DNS zones are managed centrally.

## Overview

This test configuration deploys an Azure Policy using the local `private-dns-zone-policies` module.

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

| Name | Description | Type | Example |
|------|-------------|------|---------|
| location                    | The Azure region for resource deployment | string | "SwedenCentral" |
| management_group_id         | The management group ID for policy assignment | string | "/providers/Microsoft.Management/managementGroups/all_subscriptions" |
| dns_zones_resource_group_id | The resource group ID containing the DNS zones | string | "/subscriptions/111111-111-111-111/resourceGroups/rg-plat-lz-2" |

## Outputs

| Name | Description |
|------|-------------|
| policy_initiative_id | The ID of the policy initiative (policy set definition) |
| enabled_policies | List of enabled policy types based on provided DNS zone IDs |


## Cleanup

To destroy the resources:
```bash
terraform destroy
```

## Trigger Policy Scan

Ypou can use the following commands to trigger a policy evaluation after deployment:

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

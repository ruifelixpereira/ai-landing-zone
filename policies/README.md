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

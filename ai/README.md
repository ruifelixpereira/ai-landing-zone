# AI Landing Zone Module Test

This directory contains the test configuration for the `ai-lz` module.

## Overview

This test configuration deploys an Azure AI Landing Zone using the local `ai-lz` module, which wraps the [Azure Verified Module for AI/ML Landing Zone](https://registry.terraform.io/modules/Azure/avm-ptn-aiml-landing-zone/azurerm/latest).

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

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_telemetry | Enable telemetry collection for the module | bool | false |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | The name of the resource group |
| resource_group_id | The ID of the resource group |
| ai_foundry_hub_id | The ID of the AI Foundry Hub |
| ai_foundry_hub_name | The name of the AI Foundry Hub |
| vnet_id | The ID of the Virtual Network |
| vnet_name | The name of the Virtual Network |

## Cleanup

To destroy the resources:
```bash
terraform destroy
```

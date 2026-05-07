# AI Application Landing Zone Module Test

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

### AI Foundry create timeout workaround

If Azure AI Foundry account creation returns `context deadline exceeded` while the account is still provisioning in Azure:

1. Keep `create_ai_agent_service = false` in `terraform.tfvars` and apply.
2. After the AI Foundry account reaches `Succeeded`, set `create_ai_agent_service = true` and apply again.

### Recovery when resource exists but is not in state

If `terraform apply` fails with a message that the AI Foundry account already exists, import it into state and continue:

```bash
# 1) Set the existing AI Foundry resource ID (use your real values)
export AI_FOUNDRY_ID="/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.CognitiveServices/accounts/<ACCOUNT_NAME>"

# 2) Import the nested module resource address used by this solution
terraform import \
   'module.ai_landing_zone.module.ai_landing_zone.module.foundry_ptn.azapi_resource.ai_foundry' \
   "$AI_FOUNDRY_ID"

# 3) Reconcile state with Azure and review the delta
terraform plan -refresh-only
terraform plan

# 4) Continue deployment
terraform apply
```

If the import command says the address already exists in state, run:

```bash
terraform state show 'module.ai_landing_zone.module.ai_landing_zone.module.foundry_ptn.azapi_resource.ai_foundry'
```

### External APIMSubnet ownership

To manage APIMSubnet outside this stack while still letting the AI Landing Zone module create other subnets:

1. Set `manage_apim_subnet = false` in `terraform.tfvars`.
2. If APIMSubnet was previously managed by this stack, remove only that resource from state before apply:

```bash
terraform state rm 'module.ai_landing_zone.module.ai_landing_zone.module.byo_subnets["APIMSubnet"].azapi_resource.subnet[0]'
```

3. Run:

```bash
terraform plan
terraform apply
```

### APIMSubnet delegation conflict workaround

If apply fails with `SubnetMissingRequiredDelegation` on `APIMSubnet` and mentions `serviceAssociationLinks/AppServiceLink`:

1. Set `manage_apim_subnet = false` in `terraform.tfvars`.
2. Re-run `terraform apply`.

This prevents the upstream module from issuing a subnet PUT that removes required delegation metadata on an already-associated subnet.

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

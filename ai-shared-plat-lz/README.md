# AI Shared Platform Landing Zones

The deployment of the AI Shared Platform Landing Zones follows the steps outlined in the [full deployment guide](https://github.com/Azure-Samples/ai-hub-gateway-solution-accelerator/blob/citadel-v1/guides/full-deployment-guide.md). Below are the specific instructions for the AI Foundry Shared Platform Landing Zone, which serves as a central spoke in the hub-and-spoke architecture, aligned with the **network architecture approach 2** outlined in the [guide](https://github.com/Azure-Samples/ai-hub-gateway-solution-accelerator/blob/citadel-v1/guides/full-deployment-guide.md#approach-2-hub-spoke-hub-citadel-as-dedicated-spoke).

## Step 1. Validate Prerequisites

1. Validate required resource providers in your subscription. You can check here the [required providers](https://github.com/Azure-Samples/ai-hub-gateway-solution-accelerator/blob/citadel-v1/guides/full-deployment-guide.md#required-resource-providers) to setup.

2. Make sure you have the following [Deployment tools](https://github.com/Azure-Samples/ai-hub-gateway-solution-accelerator/blob/citadel-v1/guides/full-deployment-guide.md#deployment-tools) installed in your local machine.

## Step 2. Prepare your environment

```bash
cd ai-shared-plat-lz

# Create a working directory:
mkdir ai-hub-citadel-deployment

# Make the repository your current directory:
cd ai-hub-citadel-deployment # it may differ if you used git clone


# Copy repo files
azd init --template Azure-Samples/ai-hub-gateway-solution-accelerator -e ai-hub-citadel-dev --branch citadel-v1

cd ai-hub-gateway-solution-accelerator

# Copy and customize the bicep/infra/main.bicepparam file with your values
mv bicep/infra/main.bicepparam bicep/infra/main.bicepparam.backup
cp ../../config/main.bicepparam.template bicep/infra/main.bicepparam
```

## Step 3. Deploy with azd

```bash
# This automatically picks up the main.bicepparam file. You can override specific parameters using environment variables or by modifying the main.bicepparam file directly.

# Authenticate to Azure
# append --tenant-id <your-tenant-id> if needed
#azd auth login --tenant-id <your-tenant-id>
azd auth login --tenant-id 71834302-da70-4741-ba0b-c3b9404e38a6

# Initialize environment and give it a name (e.g. ai-hub-citadel-dev-01)
#azd env new <your-environment-name>
azd env new ai-hub-citadel-dev-01

# Copy the .env file to your environment and customize it with your values
#cp ../../config/.env.template .azure/<your-environment-name>/.env
cp ../../config/.env.template .azure/ai-hub-citadel-dev-01/.env

# Provision and deploy everything based on defaults
azd up
```

## Step 4. Verify Resource Deployment

```bash
# List all resources in resource group
RG_NAME=$(az deployment sub show \
  --name <deployment-name> \
  --query properties.outputs.resourceGroupName.value -o tsv)

az resource list \
  --resource-group $RG_NAME \
  --output table
```





// privatelink.openai.azure.com
// privatelink.vaultcore.azure.net
// privatelink.monitor.azure.com
// privatelink.servicebus.windows.net
// privatelink.documents.azure.com
// privatelink.blob.core.windows.net
// privatelink.file.core.windows.net
// privatelink.table.core.windows.net
// privatelink.queue.core.windows.net
// privatelink.cognitiveservices.azure.com
// privatelink.azure-api.net
// privatelink.services.azure.com
// privatelink.redis.azure.net

services.ai.azure.com
vault.azure.net
-----
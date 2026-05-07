# AI Shared Platform Landing Zones

The deployment of the AI Shared Platform Landing Zones follows the steps outlined in the [full deployment guide](https://github.com/Azure-Samples/ai-hub-gateway-solution-accelerator/blob/citadel-v1/guides/full-deployment-guide.md). Below are the specific instructions for the AI Foundry Shared Platform Landing Zone, which serves as a central spoke in the hub-and-spoke architecture, aligned with the **network architecture approach 2** outlined in the [guide](https://github.com/Azure-Samples/ai-hub-gateway-solution-accelerator/blob/citadel-v1/guides/full-deployment-guide.md#approach-2-hub-spoke-hub-citadel-as-dedicated-spoke).

## Step 1. Validate Prerequisites

1. Validate required resource providers in your subscription. You can check here the [required providers](https://github.com/Azure-Samples/ai-hub-gateway-solution-accelerator/blob/citadel-v1/guides/full-deployment-guide.md#required-resource-providers) to setup.

2. Make sure you have the following [Deployment tools](https://github.com/Azure-Samples/ai-hub-gateway-solution-accelerator/blob/citadel-v1/guides/full-deployment-guide.md#deployment-tools) installed in your local machine.

## Step 2. Prepare your environment

```bash
cd ai-shared-plat-lz/ai-hub-gateway-solution-accelerator

# Copy and customize the bicep/infra/main.bicepparam file with your values
mv bicep/infra/main.bicepparam bicep/infra/main.bicepparam.backup
cp ../config/main.bicepparam.template bicep/infra/main.bicepparam
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
azd env new ai-hub-dev-01

# Copy the .env file to your environment and customize it with your values
#cp ../config/.env.template .azure/<your-environment-name>/.env
cp ../config/.env.template .azure/ai-hub-dev-01/.env

# You can check your environment
azd env get-values

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

## Private DNS Zones

The AI Foundry Shared Platform Landing Zone requires several private endpoints that use private DNS zones. This is the list of private DNS zones that are commonly used for AI Foundry workloads:

- privatelink.openai.azure.com
- privatelink.vaultcore.azure.net
- privatelink.monitor.azure.com
- privatelink.servicebus.windows.net
- privatelink.documents.azure.com
- privatelink.blob.core.windows.net
- privatelink.file.core.windows.net
- privatelink.table.core.windows.net
- privatelink.queue.core.windows.net
- privatelink.cognitiveservices.azure.com
- privatelink.azure-api.net
- privatelink.services.azure.com
- privatelink.redis.azure.net

Since we are using the network architecture approach 2, and we have a Hub connectivity LZ with the shared networking components, including the private DNS zones, to avoid the AI Foundry Shared Platform Landing Zone to create new private DNS zones by default we need to configure our environment to pass the existing private DNS zones resource IDs. This is done by including these variables in your environment:

```bash
EXISTING_DNS_ZONE_AI_SERVICES="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.services.ai.azure.com"
EXISTING_DNS_ZONE_APIM="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.azure-api.net"
EXISTING_DNS_ZONE_COGNITIVE="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.cognitiveservices.azure.com"
EXISTING_DNS_ZONE_COSMOSDB="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com"
EXISTING_DNS_ZONE_EVENTHUB="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"
EXISTING_DNS_ZONE_KEYVAULT="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
EXISTING_DNS_ZONE_MONITOR="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.monitor.azure.com"
EXISTING_DNS_ZONE_OPENAI="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
EXISTING_DNS_ZONE_REDIS="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.redis.azure.net"
EXISTING_DNS_ZONE_STORAGE_BLOB="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
EXISTING_DNS_ZONE_STORAGE_FILE="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
EXISTING_DNS_ZONE_STORAGE_QUEUE="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
EXISTING_DNS_ZONE_STORAGE_TABLE="/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group-name>/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"
```

/*
Private Endpoint and DNS Configuration Module
------------------------------------------
This module configures private network access for Azure services using:

1. Private Endpoints:
   - Creates network interfaces in the specified subnet
   - Establishes private connections to Azure services
   - Enables secure access without public internet exposure

2. Private DNS Zones:
   - Enables custom DNS resolution for private endpoints

3. DNS Zone Links:
   - Links private DNS zones to the VNet
   - Enables name resolution for resources in the VNet
   - Prevents DNS resolution conflicts

Security Benefits:
- Eliminates public internet exposure
- Enables secure access from within VNet
- Prevents data exfiltration through network
*/

// Resource names and identifiers
@description('Name of the AI Foundry account')
param aiAccountName string
@description('Name of the AI Search service')
param aiSearchName string
@description('Name of the storage account')
param storageName string
@description('Name of the Cosmos DB account')
param cosmosDBName string
@description('Name of the API Management service (optional)')
param apiManagementName string = ''
@description('Name of the Vnet')
param vnetName string
@description('Name of the Customer subnet')
param peSubnetName string
@description('Suffix for unique resource names')
param suffix string

@description('Resource Group name for existing Virtual Network (if different from current resource group)')
param vnetResourceGroupName string = resourceGroup().name

@description('Subscription ID for Virtual Network')
param vnetSubscriptionId string = subscription().subscriptionId

@description('Resource Group name for Storage Account')
param storageAccountResourceGroupName string = resourceGroup().name

@description('Subscription ID for Storage account')
param storageAccountSubscriptionId string = subscription().subscriptionId

@description('Subscription ID for AI Search service')
param aiSearchSubscriptionId string = subscription().subscriptionId

@description('Resource Group name for AI Search service')
param aiSearchResourceGroupName string = resourceGroup().name

@description('Subscription ID for Cosmos DB account')
param cosmosDBSubscriptionId string = subscription().subscriptionId

@description('Resource group name for Cosmos DB account')
param cosmosDBResourceGroupName string = resourceGroup().name

@description('Subscription ID for API Management service (optional)')
param apiManagementSubscriptionId string = subscription().subscriptionId

@description('Resource group name for API Management service (optional)')
param apiManagementResourceGroupName string = resourceGroup().name

@description('Map of DNS zone FQDNs to full ARM resource IDs. If provided, reference existing DNS zones instead of creating them.')
param existingDnsZones object = {
  'privatelink.services.ai.azure.com': ''
  'privatelink.openai.azure.com': ''
  'privatelink.cognitiveservices.azure.com': ''
  'privatelink.search.windows.net': ''
  'privatelink.blob.${environment().suffixes.storage}': ''
  'privatelink.documents.azure.com': ''
  'privatelink.azure-api.net': ''
}

// ---- Resource references ----
resource aiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiAccountName
  scope: resourceGroup()
}

resource aiSearch 'Microsoft.Search/searchServices@2023-11-01' existing = {
  name: aiSearchName
  scope: resourceGroup(aiSearchSubscriptionId, aiSearchResourceGroupName)
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageName
  scope: resourceGroup(storageAccountSubscriptionId, storageAccountResourceGroupName)
}

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
  name: cosmosDBName
  scope: resourceGroup(cosmosDBSubscriptionId, cosmosDBResourceGroupName)
}

resource apiManagementService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = if (!empty(apiManagementName)) {
  name: apiManagementName
  scope: resourceGroup(apiManagementSubscriptionId, apiManagementResourceGroupName)
}

// Reference existing network resources
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetSubscriptionId, vnetResourceGroupName)
}
resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: peSubnetName
}

/* -------------------------------------------- AI Foundry Account Private Endpoint -------------------------------------------- */

// Private endpoint for AI Services account
// - Creates network interface in customer hub subnet
// - Establishes private connection to AI Services account
resource aiAccountPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${aiAccountName}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: { id: peSubnet.id } // Deploy in customer hub subnet
    privateLinkServiceConnections: [
      {
        name: '${aiAccountName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: aiAccount.id
          groupIds: [ 'account' ] // Target AI Services account
        }
      }
    ]
  }
}

/* -------------------------------------------- AI Search Private Endpoint -------------------------------------------- */

// Private endpoint for AI Search
// - Creates network interface in customer hub subnet
// - Establishes private connection to AI Search service
resource aiSearchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${aiSearchName}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: { id: peSubnet.id } // Deploy in customer hub subnet
    privateLinkServiceConnections: [
      {
        name: '${aiSearchName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: aiSearch.id
          groupIds: [ 'searchService' ] // Target search service
        }
      }
    ]
  }
}

/* -------------------------------------------- Storage Private Endpoint -------------------------------------------- */

// Private endpoint for Storage Account
// - Creates network interface in customer hub subnet
// - Establishes private connection to blob storage
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${storageName}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: { id: peSubnet.id } // Deploy in customer hub subnet
    privateLinkServiceConnections: [
      {
        name: '${storageName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: storageAccount.id // Target blob storage
          groupIds: [ 'blob' ]
        }
      }
    ]
  }
}

/*--------------------------------------------- Cosmos DB Private Endpoint -------------------------------------*/

resource cosmosDBPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${cosmosDBName}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: { id: peSubnet.id } // Deploy in customer hub subnet
    privateLinkServiceConnections: [
      {
        name: '${cosmosDBName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: cosmosDBAccount.id // Target Cosmos DB account
          groupIds: [ 'Sql' ]
        }
      }
    ]
  }
}

/*--------------------------------------------- API Management Private Endpoint -------------------------------------*/

resource apiManagementPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (!empty(apiManagementName)) {
  name: '${apiManagementName}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: { id: peSubnet.id } // Deploy in customer hub subnet
    privateLinkServiceConnections: [
      {
        name: '${apiManagementName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: apiManagementService.id // Target API Management service
          groupIds: [ 'Gateway' ] // Gateway endpoint for API calls
        }
      }
    ]
  }
}

/* -------------------------------------------- Private DNS Zones -------------------------------------------- */

// Format: 1) Private DNS Zone
//         2) Link Private DNS Zone to VNet
//         3) Create DNS Zone Group for Private Endpoint

// Private DNS Zone for AI Services (Account)
// 1) Enables custom DNS resolution for AI Services private endpoint

var aiServicesDnsZoneName = 'privatelink.services.ai.azure.com'
var openAiDnsZoneName = 'privatelink.openai.azure.com'
var cognitiveServicesDnsZoneName = 'privatelink.cognitiveservices.azure.com'
var aiSearchDnsZoneName = 'privatelink.search.windows.net'
var storageDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var cosmosDBDnsZoneName = 'privatelink.documents.azure.com'
var apiManagementDnsZoneName = 'privatelink.azure-api.net'

// ---- DNS Zone Resource ID lookups ----
var aiServicesDnsZoneResourceId = existingDnsZones[aiServicesDnsZoneName]
var openAiDnsZoneResourceId = existingDnsZones[openAiDnsZoneName]
var cognitiveServicesDnsZoneResourceId = existingDnsZones[cognitiveServicesDnsZoneName]
var aiSearchDnsZoneResourceId = existingDnsZones[aiSearchDnsZoneName]
var storageDnsZoneResourceId = existingDnsZones[storageDnsZoneName]
var cosmosDBDnsZoneResourceId = existingDnsZones[cosmosDBDnsZoneName]
var apiManagementDnsZoneResourceId = existingDnsZones[apiManagementDnsZoneName]

// Pad split results so malformed IDs fail at the resource scope instead of an array index lookup.
var dnsZoneResourceIdPadding = [
  ''
  ''
  ''
  ''
  ''
]
var aiServicesDnsZoneResourceIdParts = concat(split(aiServicesDnsZoneResourceId, '/'), dnsZoneResourceIdPadding)
var openAiDnsZoneResourceIdParts = concat(split(openAiDnsZoneResourceId, '/'), dnsZoneResourceIdPadding)
var cognitiveServicesDnsZoneResourceIdParts = concat(split(cognitiveServicesDnsZoneResourceId, '/'), dnsZoneResourceIdPadding)
var aiSearchDnsZoneResourceIdParts = concat(split(aiSearchDnsZoneResourceId, '/'), dnsZoneResourceIdPadding)
var storageDnsZoneResourceIdParts = concat(split(storageDnsZoneResourceId, '/'), dnsZoneResourceIdPadding)
var cosmosDBDnsZoneResourceIdParts = concat(split(cosmosDBDnsZoneResourceId, '/'), dnsZoneResourceIdPadding)
var apiManagementDnsZoneResourceIdParts = concat(split(apiManagementDnsZoneResourceId, '/'), dnsZoneResourceIdPadding)

var aiServicesDnsZoneSubscriptionId = empty(aiServicesDnsZoneResourceId) ? subscription().subscriptionId : aiServicesDnsZoneResourceIdParts[2]
var openAiDnsZoneSubscriptionId = empty(openAiDnsZoneResourceId) ? subscription().subscriptionId : openAiDnsZoneResourceIdParts[2]
var cognitiveServicesDnsZoneSubscriptionId = empty(cognitiveServicesDnsZoneResourceId) ? subscription().subscriptionId : cognitiveServicesDnsZoneResourceIdParts[2]
var aiSearchDnsZoneSubscriptionId = empty(aiSearchDnsZoneResourceId) ? subscription().subscriptionId : aiSearchDnsZoneResourceIdParts[2]
var storageDnsZoneSubscriptionId = empty(storageDnsZoneResourceId) ? subscription().subscriptionId : storageDnsZoneResourceIdParts[2]
var cosmosDBDnsZoneSubscriptionId = empty(cosmosDBDnsZoneResourceId) ? subscription().subscriptionId : cosmosDBDnsZoneResourceIdParts[2]
var apiManagementDnsZoneSubscriptionId = empty(apiManagementDnsZoneResourceId) ? subscription().subscriptionId : apiManagementDnsZoneResourceIdParts[2]

var aiServicesDnsZoneResourceGroupName = empty(aiServicesDnsZoneResourceId) ? resourceGroup().name : aiServicesDnsZoneResourceIdParts[4]
var openAiDnsZoneResourceGroupName = empty(openAiDnsZoneResourceId) ? resourceGroup().name : openAiDnsZoneResourceIdParts[4]
var cognitiveServicesDnsZoneResourceGroupName = empty(cognitiveServicesDnsZoneResourceId) ? resourceGroup().name : cognitiveServicesDnsZoneResourceIdParts[4]
var aiSearchDnsZoneResourceGroupName = empty(aiSearchDnsZoneResourceId) ? resourceGroup().name : aiSearchDnsZoneResourceIdParts[4]
var storageDnsZoneResourceGroupName = empty(storageDnsZoneResourceId) ? resourceGroup().name : storageDnsZoneResourceIdParts[4]
var cosmosDBDnsZoneResourceGroupName = empty(cosmosDBDnsZoneResourceId) ? resourceGroup().name : cosmosDBDnsZoneResourceIdParts[4]
var apiManagementDnsZoneResourceGroupName = empty(apiManagementDnsZoneResourceId) ? resourceGroup().name : apiManagementDnsZoneResourceIdParts[4]

// ---- DNS Zone Resources and References ----
resource aiServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (empty(aiServicesDnsZoneResourceId)) {
  name: aiServicesDnsZoneName
  location: 'global'
}

// Reference existing private DNS zone if provided
resource existingAiServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(aiServicesDnsZoneResourceId)) {
  name: aiServicesDnsZoneName
  scope: resourceGroup(aiServicesDnsZoneSubscriptionId, aiServicesDnsZoneResourceGroupName)
}
//creating condition if user pass existing dns zones or not
var aiServicesDnsZoneId = empty(aiServicesDnsZoneResourceId) ? aiServicesPrivateDnsZone.id : existingAiServicesPrivateDnsZone.id

resource openAiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (empty(openAiDnsZoneResourceId)) {
  name: openAiDnsZoneName
  location: 'global'
}

// Reference existing private DNS zone if provided
resource existingOpenAiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(openAiDnsZoneResourceId)) {
  name: openAiDnsZoneName
  scope: resourceGroup(openAiDnsZoneSubscriptionId, openAiDnsZoneResourceGroupName)
}
//creating condition if user pass existing dns zones or not
var openAiDnsZoneId = empty(openAiDnsZoneResourceId) ? openAiPrivateDnsZone.id : existingOpenAiPrivateDnsZone.id

resource cognitiveServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (empty(cognitiveServicesDnsZoneResourceId)) {
  name: cognitiveServicesDnsZoneName
  location: 'global'
}

// Reference existing private DNS zone if provided
resource existingCognitiveServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(cognitiveServicesDnsZoneResourceId)) {
  name: cognitiveServicesDnsZoneName
  scope: resourceGroup(cognitiveServicesDnsZoneSubscriptionId, cognitiveServicesDnsZoneResourceGroupName)
}
//creating condition if user pass existing dns zones or not
var cognitiveServicesDnsZoneId = empty(cognitiveServicesDnsZoneResourceId) ? cognitiveServicesPrivateDnsZone.id : existingCognitiveServicesPrivateDnsZone.id

resource aiSearchPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (empty(aiSearchDnsZoneResourceId)) {
  name: aiSearchDnsZoneName
  location: 'global'
}

// Reference existing private DNS zone if provided
resource existingAiSearchPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(aiSearchDnsZoneResourceId)) {
  name: aiSearchDnsZoneName
  scope: resourceGroup(aiSearchDnsZoneSubscriptionId, aiSearchDnsZoneResourceGroupName)
}
//creating condition if user pass existing dns zones or not
var aiSearchDnsZoneId = empty(aiSearchDnsZoneResourceId) ? aiSearchPrivateDnsZone.id : existingAiSearchPrivateDnsZone.id

resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (empty(storageDnsZoneResourceId)) {
  name: storageDnsZoneName
  location: 'global'
}

// Reference existing private DNS zone if provided
resource existingStoragePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(storageDnsZoneResourceId)) {
  name: storageDnsZoneName
  scope: resourceGroup(storageDnsZoneSubscriptionId, storageDnsZoneResourceGroupName)
}
//creating condition if user pass existing dns zones or not
var storageDnsZoneId = empty(storageDnsZoneResourceId) ? storagePrivateDnsZone.id : existingStoragePrivateDnsZone.id

resource cosmosDBPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (empty(cosmosDBDnsZoneResourceId)) {
  name: cosmosDBDnsZoneName
  location: 'global'
}

// Reference existing private DNS zone if provided
resource existingCosmosDBPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(cosmosDBDnsZoneResourceId)) {
  name: cosmosDBDnsZoneName
  scope: resourceGroup(cosmosDBDnsZoneSubscriptionId, cosmosDBDnsZoneResourceGroupName)
}
//creating condition if user pass existing dns zones or not
var cosmosDBDnsZoneId = empty(cosmosDBDnsZoneResourceId) ? cosmosDBPrivateDnsZone.id : existingCosmosDBPrivateDnsZone.id

resource apiManagementPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (empty(apiManagementDnsZoneResourceId) && !empty(apiManagementName)) {
  name: apiManagementDnsZoneName
  location: 'global'
}

// Reference existing private DNS zone if provided
resource existingApiManagementPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(apiManagementDnsZoneResourceId) && !empty(apiManagementName)) {
  name: apiManagementDnsZoneName
  scope: resourceGroup(apiManagementDnsZoneSubscriptionId, apiManagementDnsZoneResourceGroupName)
}
//creating condition if user pass existing dns zones or not
var apiManagementDnsZoneId = !empty(apiManagementName) ? (empty(apiManagementDnsZoneResourceId) ? apiManagementPrivateDnsZone.id : existingApiManagementPrivateDnsZone.id) : ''

// ---- DNS VNet Links ----
resource aiServicesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(aiServicesDnsZoneResourceId)) {
  parent: aiServicesPrivateDnsZone
  location: 'global'
  name: 'aiServices-${suffix}-link'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}
resource openAiLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(openAiDnsZoneResourceId)) {
  parent: openAiPrivateDnsZone
  location: 'global'
  name: 'aiServicesOpenAI-${suffix}-link'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}
resource cognitiveServicesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(cognitiveServicesDnsZoneResourceId)) {
  parent: cognitiveServicesPrivateDnsZone
  location: 'global'
  name: 'aiServicesCognitiveServices-${suffix}-link'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}
resource aiSearchLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(aiSearchDnsZoneResourceId)) {
  parent: aiSearchPrivateDnsZone
  location: 'global'
  name: 'aiSearch-${suffix}-link'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}
resource storageLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(storageDnsZoneResourceId)) {
  parent: storagePrivateDnsZone
  location: 'global'
  name: 'storage-${suffix}-link'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}
resource cosmosDBLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(cosmosDBDnsZoneResourceId)) {
  parent: cosmosDBPrivateDnsZone
  location: 'global'
  name: 'cosmosDB-${suffix}-link'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}
resource apiManagementLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(apiManagementDnsZoneResourceId) && !empty(apiManagementName)) {
  parent: apiManagementPrivateDnsZone
  location: 'global'
  name: 'apiManagement-${suffix}-link'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

module existingAiServicesLink 'private-dns-zone-link.bicep' = if (!empty(aiServicesDnsZoneResourceId)) {
  name: 'aiServices-${suffix}-existing-link'
  scope: resourceGroup(aiServicesDnsZoneSubscriptionId, aiServicesDnsZoneResourceGroupName)
  params: {
    dnsZoneName: aiServicesDnsZoneName
    linkName: 'aiServices-${suffix}-link'
    vnetId: vnet.id
  }
}

module existingOpenAiLink 'private-dns-zone-link.bicep' = if (!empty(openAiDnsZoneResourceId)) {
  name: 'aiServicesOpenAI-${suffix}-existing-link'
  scope: resourceGroup(openAiDnsZoneSubscriptionId, openAiDnsZoneResourceGroupName)
  params: {
    dnsZoneName: openAiDnsZoneName
    linkName: 'aiServicesOpenAI-${suffix}-link'
    vnetId: vnet.id
  }
}

module existingCognitiveServicesLink 'private-dns-zone-link.bicep' = if (!empty(cognitiveServicesDnsZoneResourceId)) {
  name: 'aiServicesCognitiveServices-${suffix}-existing-link'
  scope: resourceGroup(cognitiveServicesDnsZoneSubscriptionId, cognitiveServicesDnsZoneResourceGroupName)
  params: {
    dnsZoneName: cognitiveServicesDnsZoneName
    linkName: 'aiServicesCognitiveServices-${suffix}-link'
    vnetId: vnet.id
  }
}

module existingAiSearchLink 'private-dns-zone-link.bicep' = if (!empty(aiSearchDnsZoneResourceId)) {
  name: 'aiSearch-${suffix}-existing-link'
  scope: resourceGroup(aiSearchDnsZoneSubscriptionId, aiSearchDnsZoneResourceGroupName)
  params: {
    dnsZoneName: aiSearchDnsZoneName
    linkName: 'aiSearch-${suffix}-link'
    vnetId: vnet.id
  }
}

module existingStorageLink 'private-dns-zone-link.bicep' = if (!empty(storageDnsZoneResourceId)) {
  name: 'storage-${suffix}-existing-link'
  scope: resourceGroup(storageDnsZoneSubscriptionId, storageDnsZoneResourceGroupName)
  params: {
    dnsZoneName: storageDnsZoneName
    linkName: 'storage-${suffix}-link'
    vnetId: vnet.id
  }
}

module existingCosmosDBLink 'private-dns-zone-link.bicep' = if (!empty(cosmosDBDnsZoneResourceId)) {
  name: 'cosmosDB-${suffix}-existing-link'
  scope: resourceGroup(cosmosDBDnsZoneSubscriptionId, cosmosDBDnsZoneResourceGroupName)
  params: {
    dnsZoneName: cosmosDBDnsZoneName
    linkName: 'cosmosDB-${suffix}-link'
    vnetId: vnet.id
  }
}

module existingApiManagementLink 'private-dns-zone-link.bicep' = if (!empty(apiManagementDnsZoneResourceId) && !empty(apiManagementName)) {
  name: 'apiManagement-${suffix}-existing-link'
  scope: resourceGroup(apiManagementDnsZoneSubscriptionId, apiManagementDnsZoneResourceGroupName)
  params: {
    dnsZoneName: apiManagementDnsZoneName
    linkName: 'apiManagement-${suffix}-link'
    vnetId: vnet.id
  }
}

// ---- DNS Zone Groups ----
resource aiServicesDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: aiAccountPrivateEndpoint
  name: '${aiAccountName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      { name: '${aiAccountName}-dns-aiserv-config', properties: { privateDnsZoneId: aiServicesDnsZoneId } }
      { name: '${aiAccountName}-dns-openai-config', properties: { privateDnsZoneId: openAiDnsZoneId } }
      { name: '${aiAccountName}-dns-cogserv-config', properties: { privateDnsZoneId: cognitiveServicesDnsZoneId } }
    ]
  }
  dependsOn: [
    aiServicesLink
    existingAiServicesLink
    openAiLink
    existingOpenAiLink
    cognitiveServicesLink
    existingCognitiveServicesLink
  ]
}
resource aiSearchDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: aiSearchPrivateEndpoint
  name: '${aiSearchName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      { name: '${aiSearchName}-dns-config', properties: { privateDnsZoneId: aiSearchDnsZoneId } }
    ]
  }
  dependsOn: [
    aiSearchLink
    existingAiSearchLink
  ]
}
resource storageDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: storagePrivateEndpoint
  name: '${storageName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      { name: '${storageName}-dns-config', properties: { privateDnsZoneId: storageDnsZoneId } }
    ]
  }
  dependsOn: [
    storageLink
    existingStorageLink
  ]
}
resource cosmosDBDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: cosmosDBPrivateEndpoint
  name: '${cosmosDBName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      { name: '${cosmosDBName}-dns-config', properties: { privateDnsZoneId: cosmosDBDnsZoneId } }
    ]
  }
  dependsOn: [
    cosmosDBLink
    existingCosmosDBLink
  ]
}
resource apiManagementDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (!empty(apiManagementName)) {
  parent: apiManagementPrivateEndpoint
  name: '${apiManagementName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      { name: '${apiManagementName}-dns-config', properties: { privateDnsZoneId: apiManagementDnsZoneId } }
    ]
  }
  dependsOn: [
    apiManagementLink
    existingApiManagementLink
  ]
}

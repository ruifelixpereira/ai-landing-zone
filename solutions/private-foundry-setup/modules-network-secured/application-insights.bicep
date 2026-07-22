@description('Azure region of the deployment.')
param location string

@description('Name of the AI Foundry account.')
param accountName string

@description('Create a new Application Insights resource or connect an existing one. If applicationInsightsResourceId is provided, the existing resource is used regardless of this value.')
@allowed([
  'new'
  'existing'
])
param newOrExistingApplicationInsights string = 'new'

@description('Name of the Application Insights resource to create, or to reference in the current resource group when applicationInsightsResourceId is not provided.')
param applicationInsightsName string = ''

@description('Full ARM resource ID of an existing Application Insights resource. When provided, no new Application Insights or Log Analytics workspace is created.')
param applicationInsightsResourceId string = ''

@description('Name of the Log Analytics workspace to create for a new workspace-based Application Insights resource.')
param logAnalyticsWorkspaceName string = ''

@description('Retention in days for the new Log Analytics workspace and Application Insights component.')
@minValue(30)
@maxValue(730)
param applicationInsightsRetentionInDays int = 90

var appInsightsParts = split(applicationInsightsResourceId, '/')
var useExistingApplicationInsights = newOrExistingApplicationInsights == 'existing' || !empty(applicationInsightsResourceId)
var appInsightsResourceGroupName = useExistingApplicationInsights && length(appInsightsParts) > 4 ? appInsightsParts[4] : resourceGroup().name
var appInsightsSubscriptionId = useExistingApplicationInsights && length(appInsightsParts) > 2 ? appInsightsParts[2] : subscription().subscriptionId
var resolvedApplicationInsightsName = !empty(applicationInsightsResourceId) && length(appInsightsParts) > 8 ? appInsightsParts[8] : (!empty(applicationInsightsName) ? applicationInsightsName : take('appi-${accountName}', 63))
var resolvedLogAnalyticsWorkspaceName = !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : take('log-${accountName}', 63)
var appInsightsConnectionName = take('${accountName}-appinsights', 33)

resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = if (!useExistingApplicationInsights) {
  name: resolvedLogAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: applicationInsightsRetentionInDays
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource newAppInsights 'Microsoft.Insights/components@2020-02-02' = if (!useExistingApplicationInsights) {
  name: resolvedApplicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    IngestionMode: 'LogAnalytics'
    RetentionInDays: applicationInsightsRetentionInDays
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (useExistingApplicationInsights) {
  name: resolvedApplicationInsightsName
  scope: resourceGroup(appInsightsSubscriptionId, appInsightsResourceGroupName)
}

resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/connections@2025-04-01-preview' = {
  name: appInsightsConnectionName
  parent: account
  properties: {
    category: 'AppInsights'
    target: useExistingApplicationInsights ? existingAppInsights!.id : newAppInsights!.id
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: useExistingApplicationInsights ? existingAppInsights!.properties.ConnectionString : newAppInsights!.properties.ConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: useExistingApplicationInsights ? existingAppInsights!.id : newAppInsights!.id
    }
  }
}

output applicationInsightsName string = useExistingApplicationInsights ? existingAppInsights!.name : newAppInsights!.name
output applicationInsightsId string = useExistingApplicationInsights ? existingAppInsights!.id : newAppInsights!.id
output appInsightsConnectionName string = appInsightsConnection.name
output logAnalyticsWorkspaceName string = useExistingApplicationInsights ? '' : logAnalyticsWorkspace!.name
output logAnalyticsWorkspaceId string = useExistingApplicationInsights ? '' : logAnalyticsWorkspace!.id

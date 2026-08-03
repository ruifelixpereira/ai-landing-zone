using '../../../main.bicep'

// ============================================================================
// Foundry Agents - Foundry Integration - Generated from Notebook
// ============================================================================

param apim = {
  subscriptionId: 'dcbc1e3b-d166-4453-8a07-5c6dd0e2b511'
  resourceGroupName: 'rg-ai-plat-lz-dev'
  name: 'apim-rfp01oswxbuiwdms54'
}

param keyVault = {
  subscriptionId: 'REPLACE'
  resourceGroupName: 'REPLACE'
  name: 'REPLACE'
}

param useTargetAzureKeyVault = false

param useCase = {
  businessUnit: 'IT'
  useCaseName: 'FoundryAgents'
  environment: 'DEV'
}

param apiNameMapping = {
  LLM: ['universal-llm-api', 'azure-openai-api', 'unified-ai-api']
}

param services = [
  {
    code: 'LLM'
    endpointSecretName: 'LLM-ENDPOINT'
    apiKeySecretName: 'LLM-KEY'
    policyXml: loadTextContent('ai-product-policy.xml')
  }
]

param productTerms = 'Access Contract created from testing notebook - Foundry Agents - Foundry Integration'

// Azure AI Foundry Integration
param useTargetFoundry = true

param foundry = {
  subscriptionId: 'dcbc1e3b-d166-4453-8a07-5c6dd0e2b511'
  resourceGroupName: 'rg-ai-app-lz-dev'
  accountName: 'foundry-agentsvfgg'
  projectName: 'prj-foundry-agentsvfgg'
}

param foundryConfig = {
  connectionNamePrefix: ''
  deploymentInPath: 'false'
  isSharedToAll: true
  inferenceAPIVersion: ''
  deploymentAPIVersion: ''
  staticModels: []
  listModelsEndpoint: ''
  getModelEndpoint: ''
  deploymentProvider: ''
  customHeaders: {}
  authConfig: {}
}


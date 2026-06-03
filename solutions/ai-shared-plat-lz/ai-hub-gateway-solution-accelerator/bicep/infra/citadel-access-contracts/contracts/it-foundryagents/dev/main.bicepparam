using '../../../main.bicep'

// ============================================================================
// Foundry Agents - Foundry Integration - Generated from Notebook
// ============================================================================

param apim = {
  subscriptionId: 'REPLACE'
  resourceGroupName: 'REPLACE'
  name: 'REPLACE'
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
  subscriptionId: 'REPLACE'
  resourceGroupName: 'REPLACE'
  accountName: 'REPLACE'
  projectName: 'REPLACE'
}

param foundryConfig = {
  connectionNamePrefix: ''
  deploymentInPath: 'false'
  isSharedToAll: false
  inferenceAPIVersion: ''
  deploymentAPIVersion: ''
  staticModels: []
  listModelsEndpoint: ''
  getModelEndpoint: ''
  deploymentProvider: ''
  customHeaders: {}
  authConfig: {}
}


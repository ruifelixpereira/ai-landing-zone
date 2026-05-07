using '../../../main.bicep'

// ============================================================================
// HR PII Masking - Anonymization/Deanonymization with State Saving - Generated from PII Testing Notebook
// ============================================================================

param apim = {
  subscriptionId: 'd2e7f84f-2790-4baa-9520-59ae8169ed0d'
  resourceGroupName: 'rg-ai-hub-citadel-dev-31'
  name: 'apim-icerk5vrptwxm'
}

param keyVault = {
  subscriptionId: '00000000-0000-0000-0000-000000000000'
  resourceGroupName: 'REPLACE'
  name: 'REPLACE'
}

param useTargetAzureKeyVault = false

param useCase = {
  businessUnit: 'HR'
  useCaseName: 'PIIMasking'
  environment: 'DEV'
}

param apiNameMapping = {
  LLM: ['universal-llm-api', 'azure-openai-api']
}

param services = [
  {
    code: 'LLM'
    endpointSecretName: 'HR-PII-LLM-ENDPOINT'
    apiKeySecretName: 'HR-PII-LLM-KEY'
    policyXml: loadTextContent('ai-product-policy.xml')
  }
]

param productTerms = 'PII Masking Access Contract - HR PII Masking - Anonymization/Deanonymization with State Saving'

// Azure AI Foundry Integration (disabled)
param useTargetFoundry = false

param foundry = {
  subscriptionId: '00000000-0000-0000-0000-000000000000'
  resourceGroupName: 'placeholder'
  accountName: 'placeholder'
  projectName: 'placeholder'
}

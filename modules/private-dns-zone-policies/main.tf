# Azure Policy for Private DNS Zone Linking
# This module creates DeployIfNotExists (DINE) policies that automatically
# configure private endpoints to use centralized private DNS zones

locals {
  # Map of private link group IDs to their corresponding DNS zone names
  # Reference: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
  private_dns_zone_configs = {
    # Storage
    blob = {
      group_id      = "blob"
      dns_zone_name = "privatelink.blob.core.windows.net"
      display_name  = "Storage Blob"
    }
    blob_secondary = {
      group_id      = "blob_secondary"
      dns_zone_name = "privatelink.blob.core.windows.net"
      display_name  = "Storage Blob Secondary"
    }
    table = {
      group_id      = "table"
      dns_zone_name = "privatelink.table.core.windows.net"
      display_name  = "Storage Table"
    }
    queue = {
      group_id      = "queue"
      dns_zone_name = "privatelink.queue.core.windows.net"
      display_name  = "Storage Queue"
    }
    file = {
      group_id      = "file"
      dns_zone_name = "privatelink.file.core.windows.net"
      display_name  = "Storage File"
    }
    web = {
      group_id      = "web"
      dns_zone_name = "privatelink.web.core.windows.net"
      display_name  = "Storage Static Website"
    }
    dfs = {
      group_id      = "dfs"
      dns_zone_name = "privatelink.dfs.core.windows.net"
      display_name  = "Storage Data Lake"
    }

    # Key Vault
    vault = {
      group_id      = "vault"
      dns_zone_name = "privatelink.vaultcore.azure.net"
      display_name  = "Key Vault"
    }

    # Azure SQL
    sqlServer = {
      group_id      = "sqlServer"
      dns_zone_name = "privatelink.database.windows.net"
      display_name  = "Azure SQL Database"
    }

    # Cosmos DB
    Sql = {
      group_id      = "Sql"
      dns_zone_name = "privatelink.documents.azure.com"
      display_name  = "Cosmos DB SQL API"
    }
    MongoDB = {
      group_id      = "MongoDB"
      dns_zone_name = "privatelink.mongo.cosmos.azure.com"
      display_name  = "Cosmos DB MongoDB API"
    }
    Cassandra = {
      group_id      = "Cassandra"
      dns_zone_name = "privatelink.cassandra.cosmos.azure.com"
      display_name  = "Cosmos DB Cassandra API"
    }
    Gremlin = {
      group_id      = "Gremlin"
      dns_zone_name = "privatelink.gremlin.cosmos.azure.com"
      display_name  = "Cosmos DB Gremlin API"
    }
    Table_cosmos = {
      group_id      = "Table"
      dns_zone_name = "privatelink.table.cosmos.azure.com"
      display_name  = "Cosmos DB Table API"
    }

    # Container Registry
    registry = {
      group_id      = "registry"
      dns_zone_name = "privatelink.azurecr.io"
      display_name  = "Container Registry"
    }

    # Azure Kubernetes Service
    management = {
      group_id      = "management"
      dns_zone_name = "privatelink.${var.location}.azmk8s.io"
      display_name  = "AKS Management"
    }

    # Event Hub
    namespace = {
      group_id      = "namespace"
      dns_zone_name = "privatelink.servicebus.windows.net"
      display_name  = "Event Hub / Service Bus"
    }

    # Azure Monitor
    azuremonitor = {
      group_id      = "azuremonitor"
      dns_zone_name = "privatelink.monitor.azure.com"
      display_name  = "Azure Monitor"
    }

    # Cognitive Services / OpenAI
    account = {
      group_id      = "account"
      dns_zone_name = "privatelink.cognitiveservices.azure.com"
      display_name  = "Cognitive Services"
    }
    openai_account = {
      group_id      = "account"
      dns_zone_name = "privatelink.openai.azure.com"
      display_name  = "Azure OpenAI"
    }

    # Azure Machine Learning / AI Foundry
    amlworkspace = {
      group_id      = "amlworkspace"
      dns_zone_name = "privatelink.api.azureml.ms"
      display_name  = "Azure ML Workspace"
    }

    # Azure Search
    searchService = {
      group_id      = "searchService"
      dns_zone_name = "privatelink.search.windows.net"
      display_name  = "Azure Cognitive Search"
    }

    # App Configuration
    configurationStores = {
      group_id      = "configurationStores"
      dns_zone_name = "privatelink.azconfig.io"
      display_name  = "App Configuration"
    }

    # Azure Synapse
    Sql_synapse = {
      group_id      = "Sql"
      dns_zone_name = "privatelink.sql.azuresynapse.net"
      display_name  = "Synapse SQL"
    }
    SqlOnDemand = {
      group_id      = "SqlOnDemand"
      dns_zone_name = "privatelink.sql.azuresynapse.net"
      display_name  = "Synapse SQL On-Demand"
    }
    Dev = {
      group_id      = "Dev"
      dns_zone_name = "privatelink.dev.azuresynapse.net"
      display_name  = "Synapse Dev"
    }

    # Azure Web Apps / Functions
    sites = {
      group_id      = "sites"
      dns_zone_name = "privatelink.azurewebsites.net"
      display_name  = "Web Apps / Functions"
    }
  }

  # Filter to only include DNS zones that are provided
  enabled_policies = {
    for key, config in local.private_dns_zone_configs :
    key => config if lookup(var.private_dns_zone_ids, config.dns_zone_name, null) != null
  }
}

# Policy Definition for each private link type
resource "azurerm_policy_definition" "private_dns_zone_link" {
  for_each = local.enabled_policies

  name         = "pe-dns-${each.key}"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Configure ${each.value.display_name} private endpoints to use private DNS zones"
  description  = "Deploy a private DNS zone group for ${each.value.display_name} private endpoints to override the DNS resolution for a private endpoint."

  management_group_id = var.management_group_id

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Network"
  })

  parameters = jsonencode({
    privateDnsZoneId = {
      type = "String"
      metadata = {
        displayName = "Private DNS Zone ID"
        description = "The private DNS zone ID for ${each.value.display_name}"
        strongType  = "Microsoft.Network/privateDnsZones"
      }
    }
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["DeployIfNotExists", "Disabled"]
      defaultValue  = "DeployIfNotExists"
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Network/privateEndpoints"
        },
        {
          count = {
            field = "Microsoft.Network/privateEndpoints/privateLinkServiceConnections[*]"
            where = {
              field  = "Microsoft.Network/privateEndpoints/privateLinkServiceConnections[*].groupIds[*]"
              equals = each.value.group_id
            }
          }
          greaterOrEquals = 1
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
      details = {
        type = "Microsoft.Network/privateEndpoints/privateDnsZoneGroups"
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7" # Network Contributor
        ]
        deployment = {
          properties = {
            mode = "incremental"
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                privateDnsZoneId = {
                  type = "string"
                }
                privateEndpointName = {
                  type = "string"
                }
                location = {
                  type = "string"
                }
              }
              resources = [
                {
                  name       = "[concat(parameters('privateEndpointName'), '/deployedByPolicy')]"
                  type       = "Microsoft.Network/privateEndpoints/privateDnsZoneGroups"
                  apiVersion = "2020-03-01"
                  location   = "[parameters('location')]"
                  properties = {
                    privateDnsZoneConfigs = [
                      {
                        name = "${each.key}-config"
                        properties = {
                          privateDnsZoneId = "[parameters('privateDnsZoneId')]"
                        }
                      }
                    ]
                  }
                }
              ]
            }
            parameters = {
              privateDnsZoneId = {
                value = "[parameters('privateDnsZoneId')]"
              }
              privateEndpointName = {
                value = "[field('name')]"
              }
              location = {
                value = "[field('location')]"
              }
            }
          }
        }
      }
    }
  })
}

# Policy Set Definition (Initiative) grouping all DNS policies
resource "azurerm_policy_set_definition" "private_dns_zone_initiative" {
  count = length(local.enabled_policies) > 0 ? 1 : 0

  name                = "pe-dns-zone-initiative"
  policy_type         = "Custom"
  display_name        = "Configure private endpoints to use private DNS zones"
  description         = "This policy initiative configures private endpoints to use centralized private DNS zones for DNS resolution."
  management_group_id = var.management_group_id

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Network"
  })

  parameters = jsonencode({
    for key, config in local.enabled_policies :
    "${key}PrivateDnsZoneId" => {
      type = "String"
      metadata = {
        displayName = "${config.display_name} Private DNS Zone ID"
        description = "The private DNS zone ID for ${config.display_name}"
      }
      defaultValue = var.private_dns_zone_ids[config.dns_zone_name]
    }
  })

  dynamic "policy_definition_reference" {
    for_each = local.enabled_policies
    content {
      policy_definition_id = azurerm_policy_definition.private_dns_zone_link[policy_definition_reference.key].id
      parameter_values = jsonencode({
        privateDnsZoneId = {
          value = "[parameters('${policy_definition_reference.key}PrivateDnsZoneId')]"
        }
        effect = {
          value = var.policy_effect
        }
      })
      reference_id = policy_definition_reference.key
    }
  }
}

# Policy Assignment at the specified scope
resource "azurerm_management_group_policy_assignment" "private_dns_zone_assignment" {
  count = var.create_assignment && length(local.enabled_policies) > 0 ? 1 : 0

  name                 = "pe-dns-zone-assign"
  display_name         = "Configure private endpoints to use private DNS zones"
  description          = "Automatically configure private endpoints to use centralized private DNS zones"
  policy_definition_id = azurerm_policy_set_definition.private_dns_zone_initiative[0].id
  management_group_id  = var.assignment_scope != null ? var.assignment_scope : var.management_group_id

  location = var.location
  identity {
    type = "SystemAssigned"
  }

  # Set parameter values from the private_dns_zone_ids map
  parameters = jsonencode({
    for key, config in local.enabled_policies :
    "${key}PrivateDnsZoneId" => {
      value = var.private_dns_zone_ids[config.dns_zone_name]
    }
  })

  non_compliance_message {
    content = "Private endpoint must be configured with a private DNS zone group linking to the centralized private DNS zones."
  }
}

# Role assignment for the policy's managed identity to create DNS zone groups
resource "azurerm_role_assignment" "policy_network_contributor" {
  count = var.create_assignment && length(local.enabled_policies) > 0 ? 1 : 0

  scope                = var.assignment_scope != null ? var.assignment_scope : var.management_group_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_management_group_policy_assignment.private_dns_zone_assignment[0].identity[0].principal_id
}

# Role assignment to read/write to private DNS zones
resource "azurerm_role_assignment" "policy_dns_zone_contributor" {
  count = var.create_assignment && length(local.enabled_policies) > 0 ? 1 : 0

  scope                = var.dns_zones_resource_group_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_management_group_policy_assignment.private_dns_zone_assignment[0].identity[0].principal_id
}

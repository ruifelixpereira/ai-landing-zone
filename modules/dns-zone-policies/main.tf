# Azure Policy for Private DNS Zone Linking
# This module creates DeployIfNotExists (DINE) policies that automatically
# configure private endpoints to use centralized private DNS zones

# Policy Definition for each private link type
# Supports multiple DNS zones per policy (e.g., AI Services needs 3 zones)
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

  # Create parameters for each DNS zone (up to 5 supported)
  parameters = jsonencode(merge(
    {
      for idx, zone in each.value.available_zones :
      "privateDnsZoneId${idx + 1}" => {
        type = "String"
        metadata = {
          displayName = "Private DNS Zone ID ${idx + 1}"
          description = "Private DNS Zone ID for ${zone}"
          strongType  = "Microsoft.Network/privateDnsZones"
        }
      }
    },
    {
      effect = {
        type = "String"
        metadata = {
          displayName = "Effect"
          description = "Enable or disable the execution of the policy"
        }
        allowedValues = ["DeployIfNotExists", "Disabled"]
        defaultValue  = "DeployIfNotExists"
      }
    }
  ))

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
              parameters = merge(
                {
                  for idx, zone in each.value.available_zones :
                  "privateDnsZoneId${idx + 1}" => {
                    type = "string"
                  }
                },
                {
                  privateEndpointName = {
                    type = "string"
                  }
                  location = {
                    type = "string"
                  }
                }
              )
              resources = [
                {
                  name       = "[concat(parameters('privateEndpointName'), '/deployedByPolicy')]"
                  type       = "Microsoft.Network/privateEndpoints/privateDnsZoneGroups"
                  apiVersion = "2020-03-01"
                  location   = "[parameters('location')]"
                  properties = {
                    privateDnsZoneConfigs = [
                      for idx, zone in each.value.available_zones :
                      {
                        name = "${each.key}-${idx}-config"
                        properties = {
                          privateDnsZoneId = "[parameters('privateDnsZoneId${idx + 1}')]"
                        }
                      }
                    ]
                  }
                }
              ]
            }
            parameters = merge(
              {
                for idx, zone in each.value.available_zones :
                "privateDnsZoneId${idx + 1}" => {
                  value = "[parameters('privateDnsZoneId${idx + 1}')]"
                }
              },
              {
                privateEndpointName = {
                  value = "[field('name')]"
                }
                location = {
                  value = "[field('location')]"
                }
              }
            )
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

  # Create parameters for each policy and each of its DNS zones
  parameters = jsonencode(merge([
    for key, config in local.enabled_policies : {
      for idx, zone in config.available_zones :
      "${key}PrivateDnsZoneId${idx + 1}" => {
        type = "String"
        metadata = {
          displayName = "${config.display_name} Private DNS Zone ID ${idx + 1}"
          description = "Private DNS Zone ID for ${zone}"
        }
        defaultValue = var.private_dns_zone_ids[zone]
      }
    }
  ]...))

  dynamic "policy_definition_reference" {
    for_each = local.enabled_policies
    content {
      policy_definition_id = azurerm_policy_definition.private_dns_zone_link[policy_definition_reference.key].id
      parameter_values = jsonencode(merge(
        {
          for idx, zone in policy_definition_reference.value.available_zones :
          "privateDnsZoneId${idx + 1}" => {
            value = "[parameters('${policy_definition_reference.key}PrivateDnsZoneId${idx + 1}')]"
          }
        },
        {
          effect = {
            value = var.policy_effect
          }
        }
      ))
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
  parameters = jsonencode(merge([
    for key, config in local.enabled_policies : {
      for idx, zone in config.available_zones :
      "${key}PrivateDnsZoneId${idx + 1}" => {
        value = var.private_dns_zone_ids[zone]
      }
    }
  ]...))

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

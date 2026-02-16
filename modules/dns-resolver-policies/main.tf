# Private DNS Resolver Forwarding Rules Module
# Creates DNS forwarding rules for all private DNS zones in a resource group

# Get inbound endpoint details if name is provided
data "azurerm_private_dns_resolver_inbound_endpoint" "inbound_endpoint" {
  count = var.dns_resolver_inbound_endpoint_name != null ? 1 : 0

  name                    = var.dns_resolver_inbound_endpoint_name
  private_dns_resolver_id = var.dns_resolver_resource_id
}

locals {
  # Get inbound endpoint IP from data source or use provided target_dns_servers
  inbound_endpoint_ip = var.dns_resolver_inbound_endpoint_name != null ? data.azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoint[0].ip_configurations[0].private_ip_address : null

  target_dns_servers = var.target_dns_servers != null ? var.target_dns_servers : (
    local.inbound_endpoint_ip != null ? [
      {
        ip_address = local.inbound_endpoint_ip
        port       = 53
      }
    ] : []
  )
}

# Get all private DNS zones in the specified resource group
data "azurerm_resources" "private_dns_zones" {
  resource_group_name = var.dns_zones_resource_group_name
  type                = "Microsoft.Network/privateDnsZones"
}

# Get details for each DNS zone
data "azurerm_private_dns_zone" "zones" {
  for_each            = toset(data.azurerm_resources.private_dns_zones.resources[*].name)
  name                = each.value
  resource_group_name = var.dns_zones_resource_group_name
}

locals {
  # Filter out excluded zones and create a map for rule creation
  dns_zones_to_process = {
    for name, zone in data.azurerm_private_dns_zone.zones :
    name => zone if !contains(var.exclude_zones, name)
  }

  # Create unique rule name from zone name
  # Use substr to limit to 80 chars (Azure limit) and ensure uniqueness
  rule_names = {
    for name, zone in local.dns_zones_to_process :
    name => substr(replace(replace(name, ".", "-"), "_", "-"), 0, 80)
  }
}

# Create DNS forwarding rules for each private DNS zone
resource "azurerm_private_dns_resolver_forwarding_rule" "rules" {
  for_each = local.dns_zones_to_process

  name                      = local.rule_names[each.key]
  dns_forwarding_ruleset_id = var.dns_forwarding_ruleset_resource_id
  domain_name               = "${each.key}."
  enabled                   = var.rule_state == "Enabled"

  dynamic "target_dns_servers" {
    for_each = local.target_dns_servers
    content {
      ip_address = target_dns_servers.value.ip_address
      port       = target_dns_servers.value.port
    }
  }
}

# ============================================================================
# Optional: Azure Policy to create DNS forwarding rules for new Private DNS Zones
# ============================================================================

resource "azurerm_policy_definition" "dns_forwarding_rule" {
  count = var.create_policy ? 1 : 0

  name         = "dns-forwarding-rule-for-zones"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Create DNS forwarding rule for Private DNS Zones"
  description  = "Automatically create a DNS forwarding rule in the centralized ruleset when a Private DNS Zone is created."

  management_group_id = var.management_group_id

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Network"
  })

  parameters = jsonencode({
    dnsForwardingRulesetId = {
      type = "String"
      metadata = {
        displayName = "DNS Forwarding Ruleset ID"
        description = "Resource ID of the DNS Forwarding Ruleset to add rules to"
      }
    }
    targetDnsServerIp = {
      type = "String"
      metadata = {
        displayName = "Target DNS Server IP"
        description = "IP address of the DNS Resolver inbound endpoint to forward queries to"
      }
    }
    targetDnsServerPort = {
      type = "Integer"
      metadata = {
        displayName = "Target DNS Server Port"
        description = "Port of the target DNS server"
      }
      defaultValue = 53
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
      field  = "type"
      equals = "Microsoft.Network/privateDnsZones"
    }
    then = {
      effect = "[parameters('effect')]"
      details = {
        type = "Microsoft.Network/dnsForwardingRulesets/forwardingRules"
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7" # Network Contributor
        ]
        existenceCondition = {
          field  = "Microsoft.Network/dnsForwardingRulesets/forwardingRules/domainName"
          equals = "[concat(field('name'), '.')]"
        }
        evaluationDelay = "AfterProvisioningSuccess"
        deployment = {
          properties = {
            mode = "incremental"
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                dnsForwardingRulesetId = {
                  type = "string"
                }
                zoneName = {
                  type = "string"
                }
                targetDnsServerIp = {
                  type = "string"
                }
                targetDnsServerPort = {
                  type = "int"
                }
              }
              variables = {
                rulesetName = "[last(split(parameters('dnsForwardingRulesetId'), '/'))]"
                ruleName    = "[replace(parameters('zoneName'), '.', '-')]"
              }
              resources = [
                {
                  type       = "Microsoft.Network/dnsForwardingRulesets/forwardingRules"
                  apiVersion = "2022-07-01"
                  name       = "[concat(variables('rulesetName'), '/', variables('ruleName'))]"
                  properties = {
                    domainName        = "[concat(parameters('zoneName'), '.')]"
                    forwardingRuleState = "Enabled"
                    targetDnsServers = [
                      {
                        ipAddress = "[parameters('targetDnsServerIp')]"
                        port      = "[parameters('targetDnsServerPort')]"
                      }
                    ]
                  }
                }
              ]
            }
            parameters = {
              dnsForwardingRulesetId = {
                value = "[parameters('dnsForwardingRulesetId')]"
              }
              zoneName = {
                value = "[field('name')]"
              }
              targetDnsServerIp = {
                value = "[parameters('targetDnsServerIp')]"
              }
              targetDnsServerPort = {
                value = "[parameters('targetDnsServerPort')]"
              }
            }
          }
        }
      }
    }
  })
}

resource "azurerm_management_group_policy_assignment" "dns_forwarding_rule" {
  count = var.create_policy ? 1 : 0

  name                 = "dns-fwd-rule-assign"
  display_name         = "Create DNS forwarding rules for Private DNS Zones"
  description          = "Automatically create DNS forwarding rules when Private DNS Zones are created"
  policy_definition_id = azurerm_policy_definition.dns_forwarding_rule[0].id
  management_group_id  = var.policy_assignment_scope != null ? var.policy_assignment_scope : var.management_group_id

  location = var.location
  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    dnsForwardingRulesetId = {
      value = var.dns_forwarding_ruleset_resource_id
    }
    targetDnsServerIp = {
      value = local.inbound_endpoint_ip
    }
    targetDnsServerPort = {
      value = 53
    }
    effect = {
      value = "DeployIfNotExists"
    }
  })

  non_compliance_message {
    content = "Private DNS Zone must have a corresponding DNS forwarding rule in the centralized ruleset."
  }
}

resource "azurerm_role_assignment" "policy_network_contributor" {
  count = var.create_policy ? 1 : 0

  scope                = var.policy_assignment_scope != null ? var.policy_assignment_scope : var.management_group_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_management_group_policy_assignment.dns_forwarding_rule[0].identity[0].principal_id
}

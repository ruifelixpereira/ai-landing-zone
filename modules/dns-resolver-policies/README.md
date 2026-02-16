# Private DNS Resolver Forwarding Rules Module

This module automatically creates DNS Forwarding Rules for all Private DNS Zones in a resource group. It's designed to work with Azure Private DNS Resolver to enable private endpoint DNS resolution across hub-spoke topologies.

## Overview

When you have private endpoints, their DNS records are stored in Private DNS Zones. For clients in spoke VNets to resolve these records, you need either:
1. VNet links from each Private DNS Zone to each spoke VNet (doesn't scale)
2. A Private DNS Resolver with forwarding rules that forward private link queries to Azure DNS

This module implements option 2 by:
1. Reading all Private DNS Zones from a specified resource group
2. Creating DNS Forwarding Rules for each zone (forwarding to Azure DNS 168.63.129.16)
3. Optionally creating an Azure Policy to automatically link VNets to the DNS Forwarding Ruleset

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Hub VNet                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Private DNS Resolver                        │   │
│  │  ┌─────────────┐         ┌─────────────────────────┐   │   │
│  │  │  Inbound    │         │  Outbound Endpoint      │   │   │
│  │  │  Endpoint   │         │  + Forwarding Ruleset   │   │   │
│  │  │  10.0.0.4   │         │    ├─ blob rule         │   │   │
│  │  └─────────────┘         │    ├─ vault rule        │   │   │
│  │                          │    ├─ registry rule     │   │   │
│  │                          │    └─ ... (auto-created)│   │   │
│  │                          └─────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────┐                   │
│  │         Private DNS Zones (RG)           │                   │
│  │  - privatelink.blob.core.windows.net     │                   │
│  │  - privatelink.vaultcore.azure.net       │                   │
│  │  - privatelink.azurecr.io                │                   │
│  │  - ...                                   │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
         ▲
         │ VNet Link (to ruleset)
         ▼
┌─────────────────────┐
│     Spoke VNet      │
│  DNS: 10.0.0.4      │  ──► Queries for privatelink.* ──► Azure DNS
└─────────────────────┘       (via forwarding rules)      (168.63.129.16)
```

## Usage

### Basic Usage - Create Forwarding Rules

```hcl
module "dns_resolver_rules" {
  source = "../modules/private-dns-resolver-policies"

  dns_zones_resource_group_name = "rg-dns-zones"
  dns_forwarding_ruleset_id     = azurerm_private_dns_resolver_dns_forwarding_ruleset.example.id
}
```

### With Policy for VNet Linking

```hcl
module "dns_resolver_rules" {
  source = "../modules/private-dns-resolver-policies"

  dns_zones_resource_group_name = "rg-dns-zones"
  dns_forwarding_ruleset_id     = azurerm_private_dns_resolver_dns_forwarding_ruleset.example.id

  # Enable Azure Policy to auto-link VNets
  create_policy         = true
  management_group_id   = "/providers/Microsoft.Management/managementGroups/my-mg"
  policy_assignment_scope = "/providers/Microsoft.Management/managementGroups/landing-zones"
  location              = "swedencentral"
}
```

### Exclude Specific Zones

```hcl
module "dns_resolver_rules" {
  source = "../modules/private-dns-resolver-policies"

  dns_zones_resource_group_name = "rg-dns-zones"
  dns_forwarding_ruleset_id     = azurerm_private_dns_resolver_dns_forwarding_ruleset.example.id

  exclude_zones = [
    "privatelink.database.windows.net",  # Handled separately
    "contoso.local"                       # Internal zone
  ]
}
```

### Custom Target DNS Servers

```hcl
module "dns_resolver_rules" {
  source = "../modules/private-dns-resolver-policies"

  dns_zones_resource_group_name = "rg-dns-zones"
  dns_forwarding_ruleset_id     = azurerm_private_dns_resolver_dns_forwarding_ruleset.example.id

  # Forward to custom DNS servers instead of Azure DNS
  target_dns_servers = [
    {
      ip_address = "10.0.0.4"
      port       = 53
    },
    {
      ip_address = "10.0.0.5"
      port       = 53
    }
  ]
}
```

## Prerequisites

Before using this module, you need:

1. **Private DNS Resolver** with an outbound endpoint
2. **DNS Forwarding Ruleset** attached to the outbound endpoint
3. **Private DNS Zones** in a resource group

Example setup:

```hcl
resource "azurerm_private_dns_resolver" "example" {
  name                = "dns-resolver"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  virtual_network_id  = azurerm_virtual_network.hub.id
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "example" {
  name                    = "outbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.example.id
  location                = azurerm_resource_group.hub.location
  subnet_id               = azurerm_subnet.dns_outbound.id
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "example" {
  name                                       = "dns-forwarding-ruleset"
  resource_group_name                        = azurerm_resource_group.hub.name
  location                                   = azurerm_resource_group.hub.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.example.id]
}

# Then use this module
module "dns_resolver_rules" {
  source = "../modules/private-dns-resolver-policies"

  dns_zones_resource_group_name = "rg-dns-zones"
  dns_forwarding_ruleset_id     = azurerm_private_dns_resolver_dns_forwarding_ruleset.example.id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dns_zones_resource_group_name | Name of the resource group containing private DNS zones | `string` | n/a | yes |
| dns_forwarding_ruleset_id | Resource ID of the DNS Forwarding Ruleset | `string` | n/a | yes |
| target_dns_servers | List of target DNS servers | `list(object)` | Azure DNS (168.63.129.16) | no |
| rule_state | State of forwarding rules (Enabled/Disabled) | `string` | `"Enabled"` | no |
| exclude_zones | DNS zone names to exclude | `set(string)` | `[]` | no |
| create_policy | Create Azure Policy for VNet linking | `bool` | `false` | no |
| management_group_id | Management group ID for policy | `string` | `null` | no |
| policy_assignment_scope | Scope for policy assignment | `string` | `null` | no |
| location | Location for policy managed identity | `string` | `"swedencentral"` | no |
| tags | Tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| forwarding_rules | Map of created DNS forwarding rules |
| processed_dns_zones | List of DNS zones that were processed |
| excluded_dns_zones | List of DNS zones that were excluded |
| policy_definition_id | ID of the VNet link policy definition |
| policy_assignment_id | ID of the VNet link policy assignment |

## How It Works

1. **Discovery**: The module queries Azure for all `Microsoft.Network/privateDnsZones` resources in the specified resource group.

2. **Rule Creation**: For each DNS zone, it creates a forwarding rule in the specified ruleset:
   - Domain: `<zone-name>.` (e.g., `privatelink.blob.core.windows.net.`)
   - Target: Azure DNS (168.63.129.16) by default

3. **Resolution Flow**: When a spoke VNet client queries for a private endpoint FQDN:
   - Query goes to Private DNS Resolver (configured as VNet DNS)
   - Resolver matches the forwarding rule
   - Forwards to Azure DNS
   - Azure DNS resolves using the Private DNS Zone (which has VNet link to hub)
   - Returns private IP to client

## Policy Behavior (Optional)

When `create_policy = true`, the module creates a DeployIfNotExists policy that:
- Detects VNets without a link to the DNS Forwarding Ruleset
- Automatically creates the VNet link
- Requires Network Contributor permissions (granted via managed identity)

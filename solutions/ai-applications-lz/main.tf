# AI Application Landing Zone Module Test
# This configuration calls the ai-application-lz module for testing purposes

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Get the deployer IP address to allow for public write to the key vault. This is to make sure the tests run.
# In practice your deployer machine will be on a private network and this will not be required.
#data "http" "ip" {
#  url = "https://api.ipify.org/"
#  retry {
#    attempts     = 5
#    max_delay_ms = 1000
#    min_delay_ms = 500
#  }
#}

# Add a vnet in a separate resource group
resource "azurerm_resource_group" "vnet_rg" {
  location = var.location
  name     = var.networking_resource_group_name
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  location      = azurerm_resource_group.vnet_rg.location
  parent_id     = azurerm_resource_group.vnet_rg.id
  address_space = [var.vnet_address_space]
  name          = var.vnet_name
}

module "ai_app_landing_zone" {
  source  = "Azure/avm-ptn-aiml-landing-zone/azurerm"
  version = "0.4.2"

  location            = var.location
  resource_group_name = var.ai_resource_group_name

  vnet_definition = {
    existing_byo_vnet = {
      this_vnet = {
        vnet_resource_id    = module.vnet.resource_id
      }

    }
  }

  ai_foundry_definition = {
    create_byor = true
    purge_on_destroy = true
    ai_foundry = {
      create_ai_agent_service    = false
      enable_diagnostic_settings = true
    }
  }

  apim_definition = {
    deploy = false
    publisher_email = "DoNotReply@exampleEmail.com"
    publisher_name  = "Azure API Management"
  }

  app_gateway_definition = {
    deploy = false
    backend_address_pools = {}
    backend_http_settings = {}
    frontend_ports = {}
    http_listeners = {}
    request_routing_rules = {}
  }

  bastion_definition = {
    deploy = false
  }

  container_app_environment_definition = {
    deploy = false
  }

  enable_telemetry           = false
  flag_platform_landing_zone = true

  genai_container_registry_definition = {
    deploy = false
  }

  genai_cosmosdb_definition = {
    deploy = false
  }

  genai_key_vault_definition = {
    deploy = false
  }

  genai_storage_account_definition = {
    deploy = false
  }

  genai_app_configuration_definition = {
    deploy = false
  }

  ks_ai_search_definition = {
    deploy = false
  }

  ks_bing_grounding_definition = {
    deploy = false
  }

  buildvm_definition = {
    deploy = false
  }

  jumpvm_definition = {
    deploy = false
  }

  firewall_definition = {
    deploy = false
  }

  law_definition = {
    deploy = true
  }

  #private_dns_zones = {
  #  azure_policy_pe_zone_linking_enabled      = true
  #  existing_zones_resource_group_resource_id = var.existing_zones_resource_group_resource_id
  #}
}

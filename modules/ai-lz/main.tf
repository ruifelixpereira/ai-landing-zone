module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Get the deployer IP address to allow for public write to the key vault. This is to make sure the tests run.
# In practice your deployer machine will be on a private network and this will not be required.
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

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

module "ai_landing_zone" {
  source  = "Azure/avm-ptn-aiml-landing-zone/azurerm"
  version = "0.3.0"

  location            = var.location
  resource_group_name = var.ai_resource_group_name

  vnet_definition = {
    existing_byo_vnet = {
      this_vnet = {
        vnet_resource_id = module.vnet.resource_id
        firewall_ip_address   = var.existing_hub_firewall_ip_address
      }
      
    }
    vnet_peering_configuration = {
      peer_vnet_resource_id = var.existing_hub_virtual_network_resource_id
      use_remote_gateways   = true
    }
  }

  nsgs_definition = {
    resource_group_name = var.networking_resource_group_name
  }

  ai_foundry_definition = {
    purge_on_destroy = true
    ai_foundry = {
      create_ai_agent_service = true
      enable_diagnostic_settings = false
    }
    ai_model_deployments = {
      "gpt-4o" = {
        name = "gpt-4.1"
        model = {
          format  = "OpenAI"
          name    = "gpt-4.1"
          version = "2025-04-14"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 1
        }
      }
    }
    ai_projects = {
      project_1 = {
        name                       = "project-1"
        description                = "Project 1 description"
        display_name               = "Project 1 Display Name"
        create_project_connections = true
        cosmos_db_connection = {
          new_resource_map_key = "this"
        }
        ai_search_connection = {
          new_resource_map_key = "this"
        }
        storage_account_connection = {
          new_resource_map_key = "this"
        }
      }
    }
    ai_search_definition = {
      this = {
        enable_diagnostic_settings = false
      }
    }
    cosmosdb_definition = {
      this = {
        enable_diagnostic_settings = false
        consistency_level          = "Session"
      }
    }
    key_vault_definition = {
      this = {
        enable_diagnostic_settings = false
      }
    }

    storage_account_definition = {
      this = {
        enable_diagnostic_settings = false
        shared_access_key_enabled  = true #configured for testing
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
  }
  
  apim_definition = {
    deploy          = true
    sku_root        = local.apim_sku_root
    sku_capacity    = local.apim_sku_capacity
    publisher_email = "DoNotReply@exampleEmail.com"
    publisher_name  = "Azure API Management"
    enable_diagnostic_settings = false
  }

  app_gateway_definition = {
    deploy = false
    
    backend_address_pools = {
      example_pool = {
        name = "example-backend-pool"
      }
    }

    backend_http_settings = {
      example_http_settings = {
        name     = "example-http-settings"
        port     = 80
        protocol = "Http"
      }
    }

    frontend_ports = {
      example_frontend_port = {
        name = "example-frontend-port"
        port = 80
      }
    }

    http_listeners = {
      example_listener = {
        name               = "example-listener"
        frontend_port_name = "example-frontend-port"
      }
    }

    request_routing_rules = {
      example_rule = {
        name                       = "example-rule"
        rule_type                  = "Basic"
        http_listener_name         = "example-listener"
        backend_address_pool_name  = "example-backend-pool"
        backend_http_settings_name = "example-http-settings"
        priority                   = 100
      }
    }
  }
  
  bastion_definition = {
    deploy = false
    sku    = local.bastion_sku
    zones  = local.bastion_zones
  }

  firewall_definition = {
    resource_group_name = var.networking_resource_group_name
  }
  
  container_app_environment_definition = {
    deploy = true
    zone_redundancy_enabled = true
    enable_diagnostic_settings = false
  }
  
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = false
  
  genai_container_registry_definition = {
    deploy = true
    sku = local.container_registry_sku
    zone_redundancy_enabled = local.container_registry_zone_redundancy_enabled
    enable_diagnostic_settings = false
  }

  genai_cosmosdb_definition = {
    deploy = true
    enable_diagnostic_settings = false
  }
  
  genai_key_vault_definition = {
    #this is for AVM testing purposes only. Doing this as we don't have an easy for the test runner to be privately connected for testing.
    public_network_access_enabled = true
    network_acls = {
      bypass   = "AzureServices"
      ip_rules = ["${data.http.ip.response_body}/32"]
    }
  }
  
  genai_storage_account_definition = {
    deploy                   = true
    account_replication_type = local.genai_storage_account_replication_type
    enable_diagnostic_settings = false
  }

  genai_app_configuration_definition = {
    deploy = true
    enable_diagnostic_settings = false
  }
  
  ks_ai_search_definition = {
    deploy                     = true
    sku                        = local.ai_search_sku
    replica_count              = local.ai_search_replica_count
    semantic_search_sku        = local.ai_search_semantic_sku
    enable_diagnostic_settings = false
  }

  ks_bing_grounding_definition = {
    deploy = true
    sku    = local.bing_grounding_sku
  }

  buildvm_definition = {
    deploy = false
  }

  jumpvm_definition = {
    deploy = false
  }
  
  private_dns_zones = {
    azure_policy_pe_zone_linking_enabled      = true
    existing_zones_resource_group_resource_id = var.existing_zones_resource_group_resource_id
  }
}
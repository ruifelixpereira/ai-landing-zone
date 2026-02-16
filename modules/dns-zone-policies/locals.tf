locals {
  # Map of private link group IDs to their corresponding DNS zone names
  # Reference: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
  # For group_ids that require multiple DNS zones, use dns_zone_names (list)
  private_dns_zone_configs = {
    # Storage
    blob = {
      group_id       = "blob"
      dns_zone_names = ["privatelink.blob.core.windows.net"]
      display_name   = "Storage Blob"
    }
    blob_secondary = {
      group_id       = "blob_secondary"
      dns_zone_names = ["privatelink.blob.core.windows.net"]
      display_name   = "Storage Blob Secondary"
    }
    table = {
      group_id       = "table"
      dns_zone_names = ["privatelink.table.core.windows.net"]
      display_name   = "Storage Table"
    }
    queue = {
      group_id       = "queue"
      dns_zone_names = ["privatelink.queue.core.windows.net"]
      display_name   = "Storage Queue"
    }
    file = {
      group_id       = "file"
      dns_zone_names = ["privatelink.file.core.windows.net"]
      display_name   = "Storage File"
    }
    web = {
      group_id       = "web"
      dns_zone_names = ["privatelink.web.core.windows.net"]
      display_name   = "Storage Static Website"
    }
    dfs = {
      group_id       = "dfs"
      dns_zone_names = ["privatelink.dfs.core.windows.net"]
      display_name   = "Storage Data Lake"
    }

    # Key Vault
    vault = {
      group_id       = "vault"
      dns_zone_names = ["privatelink.vaultcore.azure.net"]
      display_name   = "Key Vault"
    }

    # Azure SQL
    sqlServer = {
      group_id       = "sqlServer"
      dns_zone_names = ["privatelink.database.windows.net"]
      display_name   = "Azure SQL Database"
    }

    # Cosmos DB
    Sql = {
      group_id       = "Sql"
      dns_zone_names = ["privatelink.documents.azure.com"]
      display_name   = "Cosmos DB SQL API"
    }
    MongoDB = {
      group_id       = "MongoDB"
      dns_zone_names = ["privatelink.mongo.cosmos.azure.com"]
      display_name   = "Cosmos DB MongoDB API"
    }
    Cassandra = {
      group_id       = "Cassandra"
      dns_zone_names = ["privatelink.cassandra.cosmos.azure.com"]
      display_name   = "Cosmos DB Cassandra API"
    }
    Gremlin = {
      group_id       = "Gremlin"
      dns_zone_names = ["privatelink.gremlin.cosmos.azure.com"]
      display_name   = "Cosmos DB Gremlin API"
    }
    Table_cosmos = {
      group_id       = "Table"
      dns_zone_names = ["privatelink.table.cosmos.azure.com"]
      display_name   = "Cosmos DB Table API"
    }

    # Container Registry
    registry = {
      group_id       = "registry"
      dns_zone_names = ["privatelink.azurecr.io"]
      display_name   = "Container Registry"
    }

    # Azure Kubernetes Service
    management = {
      group_id       = "management"
      dns_zone_names = ["privatelink.${var.location}.azmk8s.io"]
      display_name   = "AKS Management"
    }

    # Event Hub / Service Bus
    namespace = {
      group_id       = "namespace"
      dns_zone_names = ["privatelink.servicebus.windows.net"]
      display_name   = "Event Hub / Service Bus"
    }

    # Azure Monitor
    azuremonitor = {
      group_id       = "azuremonitor"
      dns_zone_names = ["privatelink.monitor.azure.com"]
      display_name   = "Azure Monitor"
    }

    # Cognitive Services / OpenAI / AI Services
    # A single private endpoint with group_id "account" needs records in ALL THREE zones
    account = {
      group_id       = "account"
      dns_zone_names = [
        "privatelink.cognitiveservices.azure.com",
        "privatelink.openai.azure.com",
        "privatelink.services.ai.azure.com"
      ]
      display_name = "Azure AI Services (Cognitive/OpenAI)"
    }

    # Azure Machine Learning / AI Foundry
    amlworkspace = {
      group_id       = "amlworkspace"
      dns_zone_names = ["privatelink.api.azureml.ms", "privatelink.notebooks.azure.net"]
      display_name   = "Azure ML Workspace"
    }

    # Azure Search
    searchService = {
      group_id       = "searchService"
      dns_zone_names = ["privatelink.search.windows.net"]
      display_name   = "Azure Cognitive Search"
    }

    # App Configuration
    configurationStores = {
      group_id       = "configurationStores"
      dns_zone_names = ["privatelink.azconfig.io"]
      display_name   = "App Configuration"
    }

    # Azure Synapse
    Sql_synapse = {
      group_id       = "Sql"
      dns_zone_names = ["privatelink.sql.azuresynapse.net"]
      display_name   = "Synapse SQL"
    }
    SqlOnDemand = {
      group_id       = "SqlOnDemand"
      dns_zone_names = ["privatelink.sql.azuresynapse.net"]
      display_name   = "Synapse SQL On-Demand"
    }
    Dev = {
      group_id       = "Dev"
      dns_zone_names = ["privatelink.dev.azuresynapse.net"]
      display_name   = "Synapse Dev"
    }

    # Azure Web Apps / Functions
    sites = {
      group_id       = "sites"
      dns_zone_names = ["privatelink.azurewebsites.net"]
      display_name   = "Web Apps / Functions"
    }

    # Azure API Management
    Gateway = {
      group_id       = "Gateway"
      dns_zone_names = ["privatelink.azure-api.net"]
      display_name   = "API Management"
    }
  }

  # Filter to only include configs where at least one DNS zone is provided
  enabled_policies = {
    for key, config in local.private_dns_zone_configs :
    key => merge(config, {
      # Filter dns_zone_names to only those that exist in var.private_dns_zone_ids
      available_zones = [
        for zone in config.dns_zone_names :
        zone if lookup(var.private_dns_zone_ids, zone, null) != null
      ]
    })
    if length([
      for zone in config.dns_zone_names :
      zone if lookup(var.private_dns_zone_ids, zone, null) != null
    ]) > 0
  }
}
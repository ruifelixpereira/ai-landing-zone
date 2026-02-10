locals {
  # Container Registry SKU based on environment
  # sbox or dev -> Standard, qua -> Standard, prod -> Premium
  container_registry_sku                     = var.environment == "prod" ? "Premium" : "Standard"
  container_registry_zone_redundancy_enabled = var.environment == "prod" ? true : false

  # APIM SKU based on environment
  # dev -> Standard, qua -> Standard, prod -> Premium
  apim_sku_root     = var.environment == "prod" ? "PremiumV2" : "StandardV2"
  apim_sku_capacity = var.environment == "prod" ? 3 : 1
  apim_zones        = var.environment == "prod" ? ["1", "2", "3"] : null

  # Bastion SKU and zones based on environment
  # dev -> Basic (no zones), qua -> Standard (zone 1), prod -> Standard (zones 1,2,3)
  bastion_sku   = var.environment == "dev" ? "Basic" : "Standard"
  bastion_zones = var.environment == "prod" ? ["1", "2", "3"] : []

  # Storage account replication type based on environment
  # dev -> LRS, qua -> ZRS, prod -> GRS
  genai_storage_account_replication_type = var.environment == "prod" ? "GRS" : var.environment == "qua" ? "ZRS" : "LRS"

  # AI Search based on environment
  # dev -> basic/1/free, qua -> standard/2/standard, prod -> standard2/3/standard
  ai_search_sku           = var.environment == "dev" ? "basic" : "standard"
  ai_search_replica_count = var.environment == "prod" ? 3 : var.environment == "qua" ? 2 : 1
  ai_search_semantic_sku  = var.environment == "dev" ? "free" : "standard"

  # Bing grounding SKU based on environment
  # dev -> G1, qua -> G1, prod -> G1
  bing_grounding_sku = "G1"

  apim_subnet_nsg_rules = {
    "apim_rule01" = {
      name                       = "KeyVault_Outbound"
      access                     = "Allow"
      destination_address_prefix = "AzureKeyVault"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 200
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
    "apim_rule02" = {
      name                       = "Storage_Outbound"
      access                     = "Allow"
      destination_address_prefix = "Storage"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 201
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
  }
  
}

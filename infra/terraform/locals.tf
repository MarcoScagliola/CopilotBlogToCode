locals {
  region_abbr = {
    eastus       = "eus"
    eastus2      = "eus2"
    westus2      = "wus2"
    westeurope   = "weu"
    northeurope  = "neu"
    uksouth      = "uks"
    ukwest       = "ukw"
  }

  region_token = lookup(local.region_abbr, var.azure_region, replace(var.azure_region, " ", ""))

  layers = {
    bronze = {
      catalog = "bronze_catalog"
      schema  = "bronze"
    }
    silver = {
      catalog = "silver_catalog"
      schema  = "silver"
    }
    gold = {
      catalog = "gold_catalog"
      schema  = "gold"
    }
  }

  resource_group_name = "rg-${var.workload}-${var.environment}-platform"
  workspace_name      = "dbx-${var.workload}-${var.environment}"
  key_vault_name      = substr("kv-${var.workload}-${var.environment}-${local.region_token}", 0, 24)

  layer_storage_account_names = {
    for layer, config in local.layers :
    layer => substr(lower(replace("st${var.workload}${layer}${var.environment}${local.region_token}", "-", "")), 0, 24)
  }
}
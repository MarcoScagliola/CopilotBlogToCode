locals {
  region_abbrev_map = {
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    uksouth     = "uks"
    ukwest      = "ukw"
  }

  region_abbrev = lookup(local.region_abbrev_map, lower(var.azure_region), lower(replace(var.azure_region, " ", "")))

  rg_name         = "rg-${var.workload}-${var.environment}-${local.region_abbrev}"
  workspace_name  = substr("dbw-${var.workload}-${var.environment}-${local.region_abbrev}", 0, 64)
  key_vault_name  = substr(replace("kv-${var.workload}-${var.environment}-${local.region_abbrev}", "_", ""), 0, 24)
  secret_scope    = "kv-${var.environment}-scope"

  bronze_storage_account_name = substr(lower(replace("st${var.workload}${var.environment}bronze${local.region_abbrev}", "-", "")), 0, 24)
  silver_storage_account_name = substr(lower(replace("st${var.workload}${var.environment}silver${local.region_abbrev}", "-", "")), 0, 24)
  gold_storage_account_name   = substr(lower(replace("st${var.workload}${var.environment}gold${local.region_abbrev}", "-", "")), 0, 24)

  bronze_catalog = "bronze"
  silver_catalog = "silver"
  gold_catalog   = "gold"

  bronze_schema = "bronze"
  silver_schema = "silver"
  gold_schema   = "gold"

  layer_principal_client_ids = {
    bronze = var.client_id
    silver = var.client_id
    gold   = var.client_id
  }
}

locals {
  region_abbreviation_map = {
    eastus       = "eus"
    eastus2      = "eus2"
    westus2      = "wus2"
    westeurope   = "weu"
    northeurope  = "neu"
    uksouth      = "uks"
    ukwest       = "ukw"
  }

  region_abbreviation = lookup(local.region_abbreviation_map, var.azure_region, replace(var.azure_region, " ", ""))

  resource_group_name = "rg-${var.workload}-${var.environment}-${local.region_abbreviation}"
  key_vault_name_raw  = "kv-${var.workload}-${var.environment}-${local.region_abbreviation}"
  key_vault_name      = substr(replace(lower(local.key_vault_name_raw), "_", ""), 0, 24)
  workspace_name      = "dbw-${var.workload}-${var.environment}-${local.region_abbreviation}"

  bronze_storage_account = substr(lower("st${var.workload}${var.environment}bronze${local.region_abbreviation}"), 0, 24)
  silver_storage_account = substr(lower("st${var.workload}${var.environment}silver${local.region_abbreviation}"), 0, 24)
  gold_storage_account   = substr(lower("st${var.workload}${var.environment}gold${local.region_abbreviation}"), 0, 24)

  bronze_catalog = "bronze_${var.environment}"
  silver_catalog = "silver_${var.environment}"
  gold_catalog   = "gold_${var.environment}"

  bronze_schema = "layer"
  silver_schema = "layer"
  gold_schema   = "layer"

  secret_scope = "kv-${var.environment}-scope"
}

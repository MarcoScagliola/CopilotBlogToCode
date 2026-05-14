locals {
  region_abbreviations = {
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    uksouth     = "uks"
    ukwest      = "ukw"
  }

  region_abbreviation = lookup(local.region_abbreviations, var.azure_region, replace(var.azure_region, " ", ""))

  resource_group_name = "rg-${var.workload}-${var.environment}-${local.region_abbreviation}"
  workspace_name      = "dbw-${var.workload}-${var.environment}-${local.region_abbreviation}"
  key_vault_name      = substr(replace(lower("kv-${var.workload}-${var.environment}-${local.region_abbreviation}"), "_", ""), 0, 24)

  bronze_storage_account_name = substr(lower("st${var.workload}${var.environment}bronze${local.region_abbreviation}"), 0, 24)
  silver_storage_account_name = substr(lower("st${var.workload}${var.environment}silver${local.region_abbreviation}"), 0, 24)
  gold_storage_account_name   = substr(lower("st${var.workload}${var.environment}gold${local.region_abbreviation}"), 0, 24)

  bronze_access_connector_name = "acn-${var.workload}-${var.environment}-bronze-${local.region_abbreviation}"
  silver_access_connector_name = "acn-${var.workload}-${var.environment}-silver-${local.region_abbreviation}"
  gold_access_connector_name   = "acn-${var.workload}-${var.environment}-gold-${local.region_abbreviation}"

  bronze_catalog = "bronze_${var.environment}"
  silver_catalog = "silver_${var.environment}"
  gold_catalog   = "gold_${var.environment}"

  bronze_schema = "bronze"
  silver_schema = "silver"
  gold_schema   = "gold"

  secret_scope = "kv-${var.environment}-scope"
}
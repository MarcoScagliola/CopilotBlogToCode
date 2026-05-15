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

  region_abbrev = lookup(local.region_abbreviations, var.azure_region, replace(var.azure_region, " ", ""))

  rg_name            = "rg-${var.workload}-${var.environment}-${local.region_abbrev}"
  key_vault_name_raw = "kv-${var.workload}-${var.environment}-${local.region_abbrev}"
  key_vault_name     = substr(replace(local.key_vault_name_raw, "_", ""), 0, 24)
  workspace_name     = "dbw-${var.workload}-${var.environment}-${local.region_abbrev}"

  bronze_storage_name_raw = lower("st${var.workload}${var.environment}bronze${local.region_abbrev}")
  silver_storage_name_raw = lower("st${var.workload}${var.environment}silver${local.region_abbrev}")
  gold_storage_name_raw   = lower("st${var.workload}${var.environment}gold${local.region_abbrev}")

  bronze_storage_name = substr(local.bronze_storage_name_raw, 0, 24)
  silver_storage_name = substr(local.silver_storage_name_raw, 0, 24)
  gold_storage_name   = substr(local.gold_storage_name_raw, 0, 24)

  bronze_access_connector_name = "dbac-${var.workload}-bronze-${var.environment}-${local.region_abbrev}"
  silver_access_connector_name = "dbac-${var.workload}-silver-${var.environment}-${local.region_abbrev}"
  gold_access_connector_name   = "dbac-${var.workload}-gold-${var.environment}-${local.region_abbrev}"

  bronze_catalog = "${var.workload}_bronze_${var.environment}"
  silver_catalog = "${var.workload}_silver_${var.environment}"
  gold_catalog   = "${var.workload}_gold_${var.environment}"

  bronze_schema = "bronze_schema"
  silver_schema = "silver_schema"
  gold_schema   = "gold_schema"

  secret_scope = "kv-${var.environment}-scope"

  effective_layer_client_id = var.layer_sp_mode == "existing" && var.existing_layer_sp_client_id != "" ? var.existing_layer_sp_client_id : var.client_id
}

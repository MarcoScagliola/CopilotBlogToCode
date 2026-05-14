locals {
  region_abbrev_map = {
    eastus     = "eus"
    eastus2    = "eus2"
    westus2    = "wus2"
    westeurope = "weu"
    northeurope = "neu"
    uksouth    = "uks"
    ukwest     = "ukw"
  }

  azure_region_abbrev = lookup(local.region_abbrev_map, lower(var.azure_region), replace(lower(var.azure_region), " ", ""))

  rg_name = "rg-${var.workload}-${var.environment}-${local.azure_region_abbrev}"

  key_vault_name_raw = "kv-${var.workload}-${var.environment}-${local.azure_region_abbrev}"
  key_vault_name     = substr(replace(lower(local.key_vault_name_raw), "_", ""), 0, 24)

  workspace_name = "dbw-${var.workload}-${var.environment}-${local.azure_region_abbrev}"

  bronze_storage_name_raw = "st${var.workload}${var.environment}bronze${local.azure_region_abbrev}"
  silver_storage_name_raw = "st${var.workload}${var.environment}silver${local.azure_region_abbrev}"
  gold_storage_name_raw   = "st${var.workload}${var.environment}gold${local.azure_region_abbrev}"

  bronze_storage_name = substr(replace(lower(local.bronze_storage_name_raw), "-", ""), 0, 24)
  silver_storage_name = substr(replace(lower(local.silver_storage_name_raw), "-", ""), 0, 24)
  gold_storage_name   = substr(replace(lower(local.gold_storage_name_raw), "-", ""), 0, 24)

  shared_layer_sp_client_id = var.existing_layer_sp_client_id != "" ? var.existing_layer_sp_client_id : var.client_id
  shared_layer_sp_object_id = var.existing_layer_sp_object_id != "" ? var.existing_layer_sp_object_id : var.sp_object_id
}

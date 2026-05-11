locals {
  region_abbrev_map = {
    uksouth     = "uks"
    ukwest      = "ukw"
    eastus      = "eus"
    eastus2     = "eus2"
    westus      = "wus"
    westus2     = "wus2"
    northeurope = "neu"
    westeurope  = "weu"
  }

  azure_region_abbrev = lookup(local.region_abbrev_map, lower(var.azure_region), "uks")
  name_suffix         = "${var.workload}-${var.environment}-${local.azure_region_abbrev}"

  rg_name        = "rg-${local.name_suffix}"
  workspace_name = "dbw-${local.name_suffix}"

  kv_name_raw = replace(lower("kv-${local.name_suffix}"), "_", "")
  kv_name     = substr(local.kv_name_raw, 0, 24)

  layers = toset(["bronze", "silver", "gold"])

  layer_storage_names = {
    for l in local.layers : l => substr(replace(lower("st${var.workload}${var.environment}${l}${local.azure_region_abbrev}"), "-", ""), 0, 24)
  }

  layer_catalog_names = {
    bronze = "bronze_${var.workload}_${var.environment}"
    silver = "silver_${var.workload}_${var.environment}"
    gold   = "gold_${var.workload}_${var.environment}"
  }

  layer_schema_name        = "medallion"
  secret_scope_name        = "kv-${var.environment}-scope"
  should_create_layer_sps  = var.layer_sp_mode == "create"
  layer_sp_keys            = local.should_create_layer_sps ? local.layers : toset([])

  common_tags = {
    workload     = var.workload
    environment  = var.environment
    managed_by   = "terraform"
    architecture = "secure-medallion"
  }
}

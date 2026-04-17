locals {
  region_abbrev = {
    uksouth       = "uks"
    ukwest        = "ukw"
    eastus        = "eus"
    eastus2       = "eus2"
    westus        = "wus"
    westus2       = "wus2"
    westeurope    = "weu"
    northeurope   = "neu"
    australiaeast = "aue"
  }

  region = lookup(local.region_abbrev, var.azure_region, var.azure_region)
  prefix = "${var.workload}-${var.environment}-${local.region}"

  rg_name   = "rg-${local.prefix}"
  kv_name   = "kv-${local.prefix}"
  workspace = "dbw-${local.prefix}"
  metastore = "uc-${local.prefix}"

  layers = ["bronze", "silver", "gold"]

  layer_configs = {
    for l in local.layers : l => {
      storage_account_name  = lower(replace("sa${var.workload}${substr(l, 0, 3)}${var.environment}${local.region}", "-", ""))
      access_connector_name = "ac-${local.prefix}-${l}"
      catalog_name          = "${l}_${var.workload}_${var.environment}"
      schema_name           = "default"
    }
  }

  use_existing_layer_sp = var.layer_service_principal_mode == "existing"
  apps_to_create        = local.use_existing_layer_sp ? {} : local.layer_configs

  layer_sp_client_ids = local.use_existing_layer_sp ? {
    for l in local.layers : l => var.existing_layer_sp_client_id
  } : {
    for l in local.layers : l => azuread_application.layer[l].client_id
  }

  layer_sp_object_ids = local.use_existing_layer_sp ? {
    for l in local.layers : l => var.existing_layer_sp_object_id
  } : {
    for l in local.layers : l => azuread_service_principal.layer[l].object_id
  }

  kv_secret_user_ids = distinct(concat([var.azure_sp_object_id], values(local.layer_sp_object_ids)))
}

locals {
  region_abbr_map = {
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    uksouth     = "uks"
    ukwest      = "ukw"
  }

  region_key  = lower(replace(var.azure_region, " ", ""))
  region_abbr = lookup(local.region_abbr_map, local.region_key, local.region_key)

  layers = toset(["bronze", "silver", "gold"])

  resource_group_name       = "rg-${var.workload}-${var.environment}-${local.region_abbr}"
  databricks_workspace_name = "dbw-${var.workload}-${var.environment}-${local.region_abbr}"
  databricks_mrg_name       = "mrg-${var.workload}-${var.environment}-${local.region_abbr}"
  key_vault_name_raw        = "kv-${var.workload}-${var.environment}-${local.region_abbr}"
  key_vault_name            = substr(replace(lower(local.key_vault_name_raw), "_", ""), 0, 24)
  secret_scope_name         = "kv-${var.environment}-scope"

  storage_account_names = {
    for layer in local.layers :
    layer => substr(lower("st${var.workload}${var.environment}${layer}${local.region_abbr}"), 0, 24)
  }

  access_connector_names = {
    for layer in local.layers :
    layer => "ac-${var.workload}-${var.environment}-${layer}-${local.region_abbr}"
  }

  catalog_names = {
    bronze = "${var.workload}_${var.environment}_bronze"
    silver = "${var.workload}_${var.environment}_silver"
    gold   = "${var.workload}_${var.environment}_gold"
  }

  schema_names = {
    bronze = "bronze"
    silver = "silver"
    gold   = "gold"
  }

  # In existing mode, all layers use the same principal (existing_layer_sp_*).
  # In create mode, each layer gets its own principal.
  layer_principal_client_ids = var.layer_sp_mode == "create" ? {
    for layer in local.layers : layer => azuread_application.layer[layer].client_id
  } : {
    for layer in local.layers : layer => var.existing_layer_sp_client_id
  }

  layer_principal_object_ids = var.layer_sp_mode == "create" ? {
    for layer in local.layers : layer => azuread_service_principal.layer[layer].object_id
  } : {
    for layer in local.layers : layer => var.existing_layer_sp_object_id
  }
}

locals {
  azure_region_abbrev_map = {
    uksouth    = "uks"
    ukwest     = "ukw"
    eastus     = "eus"
    eastus2    = "eus2"
    westus2    = "wus2"
    northeurope = "neu"
    westeurope = "weu"
  }

  azure_region_abbrev = lookup(local.azure_region_abbrev_map, var.azure_region, substr(replace(var.azure_region, " ", ""), 0, 4))

  canonical_name_suffix = "${var.workload}-${var.environment}-${local.azure_region_abbrev}"

  resource_group_name       = "rg-${local.canonical_name_suffix}"
  databricks_workspace_name = "dbw-${local.canonical_name_suffix}"
  key_vault_name = substr(replace(lower("kv-${local.canonical_name_suffix}"), "_", ""), 0, 24)

  layer_settings = {
    bronze = {
      catalog = "${var.workload}_${var.environment}_bronze"
      schema  = "bronze"
    }
    silver = {
      catalog = "${var.workload}_${var.environment}_silver"
      schema  = "silver"
    }
    gold = {
      catalog = "${var.workload}_${var.environment}_gold"
      schema  = "gold"
    }
  }

  storage_account_names = {
    for layer, cfg in local.layer_settings :
    layer => substr(replace(lower("st${var.workload}${var.environment}${layer}${local.azure_region_abbrev}"), "-", ""), 0, 24)
  }

  access_connector_names = {
    for layer, cfg in local.layer_settings :
    layer => "ac-${var.workload}-${var.environment}-${layer}-${local.azure_region_abbrev}"
  }

  secret_scope_name = "${var.workload}-${var.environment}-scope"

  create_layer_principals = var.layer_sp_mode == "create"

  layer_principal_client_ids = local.create_layer_principals ? {
    for layer, cfg in local.layer_settings :
    layer => azuread_service_principal.layer[layer].client_id
  } : {
    for layer, cfg in local.layer_settings :
    layer => var.existing_layer_sp_client_id
  }

  layer_principal_object_ids = local.create_layer_principals ? {
    for layer, cfg in local.layer_settings :
    layer => azuread_service_principal.layer[layer].object_id
  } : {
    for layer, cfg in local.layer_settings :
    layer => var.existing_layer_sp_object_id
  }
}

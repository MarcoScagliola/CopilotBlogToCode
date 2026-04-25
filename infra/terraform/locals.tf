locals {
  layers     = toset(["bronze", "silver", "gold"])
  layer_map  = { for layer in local.layers : layer => layer }

  normalized_region = replace(lower(var.azure_region), " ", "")
  region_abbreviations = {
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    uksouth     = "uks"
    ukwest      = "ukw"
  }
  region_abbreviation = lookup(local.region_abbreviations, local.normalized_region, substr(local.normalized_region, 0, 4))

  workload_token = substr(
    replace(replace(replace(lower(var.workload), "-", ""), "_", ""), " ", ""),
    0,
    6
  )
  environment_token = substr(
    replace(replace(replace(lower(var.environment), "-", ""), "_", ""), " ", ""),
    0,
    6
  )

  resource_group_name = "rg-${var.workload}-${var.environment}-platform"
  databricks_name     = "dbw-${var.workload}-${var.environment}-${local.region_abbreviation}"
  key_vault_name      = substr("kv-${var.workload}-${var.environment}-${local.region_abbreviation}", 0, 24)

  storage_account_names = {
    for layer in local.layers :
    layer => substr("st${local.workload_token}${local.environment_token}${layer}${random_string.suffix.result}", 0, 24)
  }

  access_connector_names = {
    for layer in local.layers :
    layer => "dbac-${var.workload}-${var.environment}-${layer}"
  }

  create_layer_identities = var.layer_sp_mode == "create"

  layer_principal_client_ids = local.create_layer_identities ? {
    for layer in local.layers : layer => azuread_application.layer[layer].client_id
  } : {
    for layer in local.layers : layer => var.existing_layer_sp_client_id
  }

  layer_principal_object_ids = local.create_layer_identities ? {
    for layer in local.layers : layer => azuread_service_principal.layer[layer].object_id
  } : {
    for layer in local.layers : layer => var.existing_layer_sp_object_id
  }

  bronze_catalog_name = "${var.environment}_bronze"
  silver_catalog_name = "${var.environment}_silver"
  gold_catalog_name   = "${var.environment}_gold"

  bronze_schema_name = "ingestion"
  silver_schema_name = "refined"
  gold_schema_name   = "curated"

  secret_scope_name = "kv-${var.environment}-scope"
}

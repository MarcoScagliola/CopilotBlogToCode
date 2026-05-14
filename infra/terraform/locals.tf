locals {
  region_abbreviations = {
    eastus       = "eus"
    eastus2      = "eus2"
    westus2      = "wus2"
    westeurope   = "weu"
    northeurope  = "neu"
    uksouth      = "uks"
    ukwest       = "ukw"
  }

  region_abbreviation = lookup(local.region_abbreviations, var.azure_region, replace(var.azure_region, " ", ""))

  layer_names = toset(["bronze", "silver", "gold"])

  name_suffix = "${var.workload}-${var.environment}-${local.region_abbreviation}"

  resource_group_name = "rg-${local.name_suffix}"
  workspace_name      = "dbw-${local.name_suffix}"
  key_vault_name      = substr(replace("kv-${local.name_suffix}", "_", ""), 0, 24)
  secret_scope_name   = "kv-${var.environment}-scope"

  catalog_names = {
    bronze = "bronze_${var.environment}"
    silver = "silver_${var.environment}"
    gold   = "gold_${var.environment}"
  }

  schema_names = {
    bronze = "bronze"
    silver = "silver"
    gold   = "gold"
  }

  layer_principal_client_ids = var.layer_sp_mode == "create" ? {
    for layer, app in azuread_application.layer : layer => app.client_id
  } : {
    for layer in local.layer_names : layer => var.existing_layer_sp_client_id
  }

  layer_principal_object_ids = var.layer_sp_mode == "create" ? {
    for layer, sp in azuread_service_principal.layer : layer => sp.object_id
  } : {
    for layer in local.layer_names : layer => var.existing_layer_sp_object_id
  }
}
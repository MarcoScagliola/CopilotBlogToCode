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

  region_abbreviation = lookup(local.region_abbreviations, var.azure_region, replace(lower(var.azure_region), " ", ""))
  layer_names         = toset(["bronze", "silver", "gold"])
  create_layer_principals = var.layer_sp_mode == "create"

  resource_group_name = "rg-${var.workload}-${var.environment}-platform"
  databricks_workspace_name = "dbw-${var.workload}-${var.environment}-${local.region_abbreviation}"
  managed_resource_group_name = "rg-${var.workload}-${var.environment}-${local.region_abbreviation}-dbx-managed"
  key_vault_name = substr(replace("kv-${var.workload}-${var.environment}-${local.region_abbreviation}", "_", ""), 0, 24)
  secret_scope_name = "${var.workload}-${var.environment}-scope"

  layer_settings = {
    for layer in local.layer_names : layer => {
      catalog_name          = "${var.workload}_${layer}"
      schema_name           = layer
      storage_account_name  = lower(substr("st${var.workload}${var.environment}${layer}${local.region_abbreviation}", 0, 24))
      access_connector_name = "ac-${var.workload}-${layer}-${var.environment}-${local.region_abbreviation}"
      application_name      = "sp-${var.workload}-${layer}-${var.environment}-${local.region_abbreviation}"
    }
  }

  layer_principal_client_ids = local.create_layer_principals ? {
    for layer, app in azuread_application.layer : layer => app.client_id
  } : {
    for layer in local.layer_names : layer => var.existing_layer_sp_client_id
  }

  layer_principal_object_ids = local.create_layer_principals ? {
    for layer, principal in azuread_service_principal.layer : layer => principal.object_id
  } : {
    for layer in local.layer_names : layer => var.existing_layer_sp_object_id
  }
}

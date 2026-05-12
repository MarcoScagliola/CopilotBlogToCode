locals {
  region_abbreviations = {
    uksouth   = "uks"
    ukwest    = "ukw"
    eastus    = "eus"
    eastus2   = "eus2"
    westeurope = "weu"
  }

  region_abbrev = lookup(local.region_abbreviations, var.azure_region, "uks")

  resource_group_name = format("rg-%s-%s-%s", var.workload, var.environment, local.region_abbrev)
  key_vault_name      = substr(replace(lower(format("kv-%s-%s-%s", var.workload, var.environment, local.region_abbrev)), "_", ""), 0, 24)
  workspace_name      = format("dbw-%s-%s-%s", var.workload, var.environment, local.region_abbrev)

  layers = toset(["bronze", "silver", "gold"])

  storage_accounts = {
    for layer in local.layers :
    layer => substr(replace(lower(format("st%s%s%s%s", var.workload, var.environment, layer, local.region_abbrev)), "-", ""), 0, 24)
  }

  access_connectors = {
    for layer in local.layers :
    layer => format("ac-%s-%s-%s-%s", var.workload, var.environment, layer, local.region_abbrev)
  }

  catalogs = {
    bronze = "bronze"
    silver = "silver"
    gold   = "gold"
  }

  schemas = {
    bronze = "main"
    silver = "main"
    gold   = "main"
  }

  secret_scope_name = format("kv-%s", var.environment)

  create_layer_sps = var.layer_sp_mode == "create"

  layer_sp_app_names = {
    for layer in local.layers :
    layer => format("app-%s-%s-%s-%s", var.workload, var.environment, layer, local.region_abbrev)
  }

  resolved_layer_client_ids = local.create_layer_sps ? {
    for layer in local.layers :
    layer => azuread_application.layer[layer].client_id
  } : {
    for layer in local.layers :
    layer => var.existing_layer_sp_client_id
  }

  resolved_layer_object_ids = local.create_layer_sps ? {
    for layer in local.layers :
    layer => azuread_service_principal.layer[layer].object_id
  } : {
    for layer in local.layers :
    layer => var.existing_layer_sp_object_id
  }

  common_tags = {
    workload    = var.workload
    environment = var.environment
    managed_by  = "terraform"
    architecture = "medallion"
  }
}

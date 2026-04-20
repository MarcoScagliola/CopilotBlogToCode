locals {
  layers = {
    bronze = "brz"
    silver = "slv"
    gold   = "gld"
  }

  region_abbreviations = {
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    uksouth     = "uks"
    ukwest      = "ukw"
  }

  region_abbr = lookup(local.region_abbreviations, var.azure_region, replace(var.azure_region, " ", ""))

  resource_group_name      = "rg-${var.workload}-${var.environment}-platform"
  databricks_workspace     = "dbw-${var.workload}-${var.environment}"
  key_vault_name           = substr(replace("kv-${var.workload}-${var.environment}-${local.region_abbr}", "_", ""), 0, 24)
  secret_scope_name        = "kv-${var.environment}-scope"
  create_layer_principals  = var.layer_sp_mode == "create"

  storage_account_names = {
    for layer, abbr in local.layers :
    layer => substr(lower("st${var.workload}${abbr}${var.environment}"), 0, 24)
  }

  layer_catalog_names = {
    bronze = "${var.environment}_bronze"
    silver = "${var.environment}_silver"
    gold   = "${var.environment}_gold"
  }
}

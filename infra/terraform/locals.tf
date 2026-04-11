locals {
  region_abbr = {
    uksouth     = "uks"
    ukwest      = "ukw"
    westeurope  = "weu"
    northeurope = "neu"
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
  }

  abbr = lookup(local.region_abbr, var.azure_region, replace(var.azure_region, "-", ""))

  # Global names
  resource_group_name = "rg-${var.workload}-${var.environment}-${local.abbr}"
  workspace_name      = "dbw-${var.workload}-${var.environment}-${local.abbr}"
  key_vault_name      = "kv-${var.workload}-${var.environment}-${local.abbr}"

  # Layer names
  layer_token = {
    bronze = "brz"
    silver = "slv"
    gold   = "gld"
  }

  storage_account_name = {
    for k, v in local.layer_token : k => "st${var.workload}${v}${var.environment}"
  }

  access_connector_name = {
    for k, v in local.layer_token : k => "dbac-${var.workload}-${v}-${var.environment}-${local.abbr}"
  }

  app_display_name = {
    for k, v in local.layer_token : k => "app-${var.workload}-${v}-${var.environment}"
  }

  catalog_name = {
    for k, v in local.layer_token : k => "${var.workload}_${v}_${var.environment}"
  }

  schema_name = {
    bronze = "bronze_schema"
    silver = "silver_schema"
    gold   = "gold_schema"
  }

  uc_storage_credential_name = {
    for k, v in local.layer_token : k => "sc-${var.workload}-${v}-${var.environment}"
  }

  uc_external_location_name = {
    for k, v in local.layer_token : k => "el-${var.workload}-${v}-${var.environment}"
  }
}

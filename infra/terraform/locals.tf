locals {
  layers = toset(["bronze", "silver", "gold"])

  region_abbr_map = {
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    uksouth     = "uks"
    ukwest      = "ukw"
  }

  azure_region_abbr = lookup(local.region_abbr_map, var.azure_region, replace(var.azure_region, " ", ""))

  rg_name             = "rg-${var.workload}-${var.environment}-${local.azure_region_abbr}"
  key_vault_name      = substr(replace(lower("kv-${var.workload}-${var.environment}-${local.azure_region_abbr}"), "_", ""), 0, 24)
  databricks_name     = "dbw-${var.workload}-${var.environment}-${local.azure_region_abbr}"
  secret_scope_name   = "kv-${var.environment}-scope"
  bronze_catalog_name = "${var.workload}_bronze"
  silver_catalog_name = "${var.workload}_silver"
  gold_catalog_name   = "${var.workload}_gold"
  bronze_schema_name  = "bronze"
  silver_schema_name  = "silver"
  gold_schema_name    = "gold"

  layer_storage_names = {
    for layer in local.layers :
    layer => substr(replace(lower("st${var.workload}${var.environment}${layer}${local.azure_region_abbr}"), "-", ""), 0, 24)
  }
}

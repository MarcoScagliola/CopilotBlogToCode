locals {
  region_abbrev_map = {
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    uksouth     = "uks"
    ukwest      = "ukw"
  }

  region_abbrev = lookup(local.region_abbrev_map, var.azure_region, replace(var.azure_region, " ", ""))

  resource_group_name = "rg-${var.workload}-${var.environment}-${local.region_abbrev}"
  workspace_name      = "dbw-${var.workload}-${var.environment}-${local.region_abbrev}"

  key_vault_raw  = lower(replace("kv-${var.workload}-${var.environment}-${local.region_abbrev}", "_", ""))
  key_vault_name = substr(local.key_vault_raw, 0, 24)

  bronze_storage_account = substr(lower("st${var.workload}${var.environment}bronze${local.region_abbrev}"), 0, 24)
  silver_storage_account = substr(lower("st${var.workload}${var.environment}silver${local.region_abbrev}"), 0, 24)
  gold_storage_account   = substr(lower("st${var.workload}${var.environment}gold${local.region_abbrev}"), 0, 24)

  bronze_catalog = "${var.workload}_bronze"
  silver_catalog = "${var.workload}_silver"
  gold_catalog   = "${var.workload}_gold"

  bronze_schema = "core"
  silver_schema = "core"
  gold_schema   = "core"

  secret_scope_name = "kv-${var.environment}-scope"
}
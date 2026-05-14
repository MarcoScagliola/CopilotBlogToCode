locals {
  region_abbrev = lookup({
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    uksouth     = "uks"
    ukwest      = "ukw"
  }, lower(var.azure_region), replace(lower(var.azure_region), " ", ""))

  resource_group_name = "rg-${var.workload}-${var.environment}-${local.region_abbrev}"

  key_vault_name = substr(
    replace(lower("kv-${var.workload}-${var.environment}-${local.region_abbrev}"), "_", ""),
    0,
    24,
  )

  workspace_name = "dbw-${var.workload}-${var.environment}-${local.region_abbrev}"

  bronze_storage_name = substr(lower("st${var.workload}${var.environment}bronze${local.region_abbrev}"), 0, 24)
  silver_storage_name = substr(lower("st${var.workload}${var.environment}silver${local.region_abbrev}"), 0, 24)
  gold_storage_name   = substr(lower("st${var.workload}${var.environment}gold${local.region_abbrev}"), 0, 24)

  bronze_catalog_name = "${var.workload}_${var.environment}_bronze"
  silver_catalog_name = "${var.workload}_${var.environment}_silver"
  gold_catalog_name   = "${var.workload}_${var.environment}_gold"

  secret_scope_name = "kv-${var.environment}-scope"

  merged_tags = merge(var.tags, {
    workload    = var.workload
    environment = var.environment
    managed_by  = "terraform"
    pattern     = "secure-medallion"
  })
}

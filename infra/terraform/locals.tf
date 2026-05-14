locals {
  region_abbrev_map = {
    eastus     = "eus"
    eastus2    = "eus2"
    westus2    = "wus2"
    westeurope = "weu"
    northeurope = "neu"
    uksouth    = "uks"
    ukwest     = "ukw"
  }

  azure_region_normalized = lower(trimspace(var.azure_region))
  azure_region_abbrev     = lookup(local.region_abbrev_map, local.azure_region_normalized, replace(local.azure_region_normalized, " ", ""))

  workload_normalized   = replace(lower(trimspace(var.workload)), " ", "")
  environment_normalized = replace(lower(trimspace(var.environment)), " ", "")

  resource_group_name = "rg-${local.workload_normalized}-${local.environment_normalized}-${local.azure_region_abbrev}"
  key_vault_name      = substr(replace(lower("kv-${local.workload_normalized}-${local.environment_normalized}-${local.azure_region_abbrev}"), "_", ""), 0, 24)
  workspace_name      = "dbw-${local.workload_normalized}-${local.environment_normalized}-${local.azure_region_abbrev}"

  bronze_storage_account_name = substr(replace(lower("st${local.workload_normalized}${local.environment_normalized}bronze${local.azure_region_abbrev}"), "-", ""), 0, 24)
  silver_storage_account_name = substr(replace(lower("st${local.workload_normalized}${local.environment_normalized}silver${local.azure_region_abbrev}"), "-", ""), 0, 24)
  gold_storage_account_name   = substr(replace(lower("st${local.workload_normalized}${local.environment_normalized}gold${local.azure_region_abbrev}"), "-", ""), 0, 24)

  bronze_filesystem_name = "landing"
  silver_filesystem_name = "landing"
  gold_filesystem_name   = "landing"

  bronze_catalog_name = "${local.workload_normalized}_${local.environment_normalized}_bronze"
  silver_catalog_name = "${local.workload_normalized}_${local.environment_normalized}_silver"
  gold_catalog_name   = "${local.workload_normalized}_${local.environment_normalized}_gold"

  bronze_schema_name = "bronze"
  silver_schema_name = "silver"
  gold_schema_name   = "gold"

  secret_scope_name = "kv-${local.environment_normalized}-scope"

  managed_resource_group_name = "${local.resource_group_name}-dbw-managed"

  bronze_access_connector_name = "ac-${local.workload_normalized}-${local.environment_normalized}-bronze-${local.azure_region_abbrev}"
  silver_access_connector_name = "ac-${local.workload_normalized}-${local.environment_normalized}-silver-${local.azure_region_abbrev}"
  gold_access_connector_name   = "ac-${local.workload_normalized}-${local.environment_normalized}-gold-${local.azure_region_abbrev}"

  bronze_application_name = "${local.workload_normalized}-${local.environment_normalized}-bronze-sp"
  silver_application_name = "${local.workload_normalized}-${local.environment_normalized}-silver-sp"
  gold_application_name   = "${local.workload_normalized}-${local.environment_normalized}-gold-sp"
}
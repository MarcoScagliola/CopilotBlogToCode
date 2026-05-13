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

  region_abbrev      = lookup(local.region_abbrev_map, var.azure_region, replace(var.azure_region, " ", ""))
  workload_sanitized = lower(replace(var.workload, "_", ""))
  environment_short  = lower(var.environment)

  resource_group_name = "rg-${local.workload_sanitized}-${local.environment_short}-${local.region_abbrev}"
  key_vault_name      = substr(replace("kv-${local.workload_sanitized}-${local.environment_short}-${local.region_abbrev}", "_", ""), 0, 24)
  databricks_name     = "dbw-${local.workload_sanitized}-${local.environment_short}-${local.region_abbrev}"

  bronze_storage_account_name = substr("st${local.workload_sanitized}${local.environment_short}br${local.region_abbrev}", 0, 24)
  silver_storage_account_name = substr("st${local.workload_sanitized}${local.environment_short}si${local.region_abbrev}", 0, 24)
  gold_storage_account_name   = substr("st${local.workload_sanitized}${local.environment_short}go${local.region_abbrev}", 0, 24)

  bronze_catalog_name = "${local.workload_sanitized}_${local.environment_short}_bronze"
  silver_catalog_name = "${local.workload_sanitized}_${local.environment_short}_silver"
  gold_catalog_name   = "${local.workload_sanitized}_${local.environment_short}_gold"

  bronze_schema_name = "core"
  silver_schema_name = "core"
  gold_schema_name   = "core"

  secret_scope_name = "kv-${local.environment_short}-scope"

  bronze_layer_sp_client_id = var.layer_sp_mode == "create" ? azuread_application.bronze.client_id : var.existing_layer_sp_client_id
  silver_layer_sp_client_id = var.layer_sp_mode == "create" ? azuread_application.silver.client_id : var.existing_layer_sp_client_id
  gold_layer_sp_client_id   = var.layer_sp_mode == "create" ? azuread_application.gold.client_id : var.existing_layer_sp_client_id

  bronze_layer_sp_object_id = var.layer_sp_mode == "create" ? azuread_service_principal.bronze.object_id : var.existing_layer_sp_object_id
  silver_layer_sp_object_id = var.layer_sp_mode == "create" ? azuread_service_principal.silver.object_id : var.existing_layer_sp_object_id
  gold_layer_sp_object_id   = var.layer_sp_mode == "create" ? azuread_service_principal.gold.object_id : var.existing_layer_sp_object_id
}

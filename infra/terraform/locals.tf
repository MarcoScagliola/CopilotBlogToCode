locals {
  region_abbrev_map = {
    eastus       = "eus"
    eastus2      = "eus2"
    westus2      = "wus2"
    westeurope   = "weu"
    northeurope  = "neu"
    uksouth      = "uks"
    ukwest       = "ukw"
  }

  region_abbrev = lookup(local.region_abbrev_map, var.azure_region, replace(var.azure_region, " ", ""))

  workload    = lower(var.workload)
  environment = lower(var.environment)

  rg_name        = "rg-${local.workload}-${local.environment}-${local.region_abbrev}"
  key_vault_name = substr(replace("kv-${local.workload}-${local.environment}-${local.region_abbrev}", "_", ""), 0, 24)
  workspace_name = "dbw-${local.workload}-${local.environment}-${local.region_abbrev}"

  bronze_storage_account = substr(lower("st${local.workload}${local.environment}bronze${local.region_abbrev}"), 0, 24)
  silver_storage_account = substr(lower("st${local.workload}${local.environment}silver${local.region_abbrev}"), 0, 24)
  gold_storage_account   = substr(lower("st${local.workload}${local.environment}gold${local.region_abbrev}"), 0, 24)

  layer_principal_client_ids = {
    bronze = coalesce(var.existing_layer_sp_client_id, var.client_id)
    silver = coalesce(var.existing_layer_sp_client_id, var.client_id)
    gold   = coalesce(var.existing_layer_sp_client_id, var.client_id)
  }
}

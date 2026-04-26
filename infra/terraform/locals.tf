locals {
  layer_names = toset(["bronze", "silver", "gold"])

  region_token = replace(var.azure_region, " ", "")
  base_name    = lower(join("-", [var.workload, var.environment, local.region_token]))

  rg_name               = "rg-${local.base_name}-platform"
  databricks_workspace  = "dbw-${local.base_name}"
  databricks_managed_rg = "rg-${local.base_name}-dbw-mrg"
  key_vault_name        = substr(replace("kv${var.workload}${var.environment}${local.region_token}", "-", ""), 0, 24)
  secret_scope_name     = "kv-scope-${var.environment}"

  layer_map = {
    for layer in local.layer_names : layer => {
      storage_account_name = substr(replace("st${var.workload}${var.environment}${layer}${local.region_token}", "-", ""), 0, 24)
      connector_name       = "ac-${var.workload}-${var.environment}-${layer}-${local.region_token}"
      catalog_name         = "${var.workload}_${layer}"
      schema_name          = "core"
    }
  }
}

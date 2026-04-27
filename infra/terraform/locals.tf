locals {
  workload_short      = substr(var.workload, 0, 3)
  environment_short   = substr(var.environment, 0, 3)
  region_abbr         = "uksso"
  resource_group_name = "rg-${var.workload}-${var.environment}-platform"

  # Layer names and settings
  layers = {
    bronze = { name = "bronze", display_name = "Bronze" }
    silver = { name = "silver", display_name = "Silver" }
    gold   = { name = "gold", display_name = "Gold" }
  }

  # Key Vault name: compute once, no trailing dash issues
  key_vault_name = substr(replace("kv${var.workload}${var.environment}${local.region_abbr}", "-", ""), 0, 24)

  common_tags = {
    workload    = var.workload
    environment = var.environment
    deployed_by = "terraform"
    deployment  = timestamp()
  }

  # Layer-specific naming
  layer_names = {
    for layer, config in local.layers :
    layer => {
      storage_account = lower(replace("st${var.workload}${layer}${var.environment}", "-", ""))
      catalog         = "${layer}_catalog"
      schema          = "bronze_schema"
    }
  }
}

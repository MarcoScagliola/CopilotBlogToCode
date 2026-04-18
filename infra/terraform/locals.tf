locals {
  base_name = lower(replace("${var.workload}-${var.environment}", "_", "-"))

  layer_names = ["bronze", "silver", "gold"]

  # Storage account names must be globally unique, lowercase alphanumeric, max 24 chars.
  layer_storage_account_names = {
    for layer in local.layer_names :
    layer => substr(replace(lower("st${var.workload}${var.environment}${layer}"), "-", ""), 0, 24)
  }

  create_layer_principals = var.layer_service_principal_mode == "create"
}

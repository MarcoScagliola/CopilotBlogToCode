locals {
  base_name = "${var.workload}-${var.environment}"
  layer_names = ["bronze", "silver", "gold"]

  layer_storage_account_names = {
    bronze = substr("st${replace(local.base_name, "-", "")}bronze", 0, 24)
    silver = substr("st${replace(local.base_name, "-", "")}silver", 0, 24)
    gold   = substr("st${replace(local.base_name, "-", "")}gold", 0, 24)
  }

  create_layer_principals = var.layer_service_principal_mode == "create"
}

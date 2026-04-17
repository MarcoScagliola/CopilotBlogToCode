output "resource_group_name" {
  value = azurerm_resource_group.platform.name
}

output "databricks_workspace_url" {
  description = "Workspace URL consumed by the DAB deployment bridge."
  value       = "https://adb-placeholder-${local.base_name}.azuredatabricks.net"
}

output "databricks_workspace_resource_id" {
  description = "Workspace resource ID consumed by bundle Azure auth configuration."
  value       = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${azurerm_resource_group.platform.name}/providers/Microsoft.Databricks/workspaces/dbw-${local.base_name}"
}

output "bronze_sp_application_id" {
  value = local.create_layer_principals ? azuread_application.layer["bronze"].client_id : var.existing_layer_sp_client_id
}

output "silver_sp_application_id" {
  value = local.create_layer_principals ? azuread_application.layer["silver"].client_id : var.existing_layer_sp_client_id
}

output "gold_sp_application_id" {
  value = local.create_layer_principals ? azuread_application.layer["gold"].client_id : var.existing_layer_sp_client_id
}

output "bronze_catalog_name" {
  value = "${var.environment}_bronze"
}

output "silver_catalog_name" {
  value = "${var.environment}_silver"
}

output "gold_catalog_name" {
  value = "${var.environment}_gold"
}

output "secret_scope_name" {
  value = "kv-${var.environment}-scope"
}

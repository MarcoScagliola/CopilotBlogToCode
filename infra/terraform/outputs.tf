output "databricks_workspace_url" {
  value       = azurerm_databricks_workspace.platform.workspace_url
  description = "Databricks workspace host"
}

output "databricks_workspace_resource_id" {
  value       = azurerm_databricks_workspace.platform.id
  description = "Databricks workspace Azure resource id"
}

output "bronze_catalog_name" {
  value = local.layer_settings.bronze.catalog
}

output "silver_catalog_name" {
  value = local.layer_settings.silver.catalog
}

output "gold_catalog_name" {
  value = local.layer_settings.gold.catalog
}

output "secret_scope_name" {
  value = local.secret_scope_name
}

output "layer_principal_client_ids" {
  value = local.layer_principal_client_ids
}

output "layer_storage_account_names" {
  value = local.storage_account_names
}

output "layer_access_connector_ids" {
  value = { for layer, resource in azurerm_databricks_access_connector.layer : layer => resource.id }
}

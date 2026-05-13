output "databricks_workspace_url" {
  value       = azurerm_databricks_workspace.main.workspace_url
  description = "Databricks workspace host URL."
}

output "databricks_workspace_resource_id" {
  value       = azurerm_databricks_workspace.main.id
  description = "Databricks workspace Azure resource ID."
}

output "bronze_catalog_name" {
  value = local.bronze_catalog_name
}

output "silver_catalog_name" {
  value = local.silver_catalog_name
}

output "gold_catalog_name" {
  value = local.gold_catalog_name
}

output "secret_scope_name" {
  value = local.secret_scope_name
}

output "layer_principal_client_ids" {
  value = local.layer_principal_client_ids
}

output "layer_storage_account_names" {
  value = { for layer, acct in azurerm_storage_account.layer : layer => acct.name }
}

output "layer_access_connector_ids" {
  value = { for layer, connector in azurerm_databricks_access_connector.layer : layer => connector.id }
}

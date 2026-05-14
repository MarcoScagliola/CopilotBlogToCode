output "databricks_workspace_url" {
  description = "Databricks workspace host URL."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Databricks workspace Azure resource ID."
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog" {
  value = local.bronze_catalog
}

output "silver_catalog" {
  value = local.silver_catalog
}

output "gold_catalog" {
  value = local.gold_catalog
}

output "bronze_schema" {
  value = local.bronze_schema
}

output "silver_schema" {
  value = local.silver_schema
}

output "gold_schema" {
  value = local.gold_schema
}

output "secret_scope" {
  value = local.secret_scope
}

output "bronze_principal_client_id" {
  value = azuread_application.bronze.client_id
}

output "silver_principal_client_id" {
  value = azuread_application.silver.client_id
}

output "gold_principal_client_id" {
  value = azuread_application.gold.client_id
}

output "bronze_storage_account" {
  value = azurerm_storage_account.bronze.name
}

output "silver_storage_account" {
  value = azurerm_storage_account.silver.name
}

output "gold_storage_account" {
  value = azurerm_storage_account.gold.name
}

output "bronze_access_connector_id" {
  value = azurerm_databricks_access_connector.bronze.id
}

output "silver_access_connector_id" {
  value = azurerm_databricks_access_connector.silver.id
}

output "gold_access_connector_id" {
  value = azurerm_databricks_access_connector.gold.id
}
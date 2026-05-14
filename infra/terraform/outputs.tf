output "databricks_workspace_url" {
  description = "Databricks workspace host URL."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Databricks workspace Azure resource ID."
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog_name" {
  value = local.catalog_names.bronze
}

output "silver_catalog_name" {
  value = local.catalog_names.silver
}

output "gold_catalog_name" {
  value = local.catalog_names.gold
}

output "secret_scope_name" {
  value = local.secret_scope_name
}

output "layer_principal_client_ids" {
  value = local.layer_principal_client_ids
}

output "layer_storage_account_names" {
  value = {
    for layer, account in azurerm_storage_account.layer : layer => account.name
  }
}

output "layer_access_connector_ids" {
  value = {
    for layer, connector in azurerm_databricks_access_connector.layer : layer => connector.id
  }
}

output "bronze_schema" {
  value = local.schema_names.bronze
}

output "silver_schema" {
  value = local.schema_names.silver
}

output "gold_schema" {
  value = local.schema_names.gold
}
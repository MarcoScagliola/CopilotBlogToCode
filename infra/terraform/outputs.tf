output "databricks_workspace_url" {
  description = "Workspace URL consumed by the DAB deploy bridge."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Azure resource ID of the Databricks workspace."
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog_name" {
  description = "Bronze catalog name."
  value       = local.layer_settings["bronze"].catalog_name
}

output "silver_catalog_name" {
  description = "Silver catalog name."
  value       = local.layer_settings["silver"].catalog_name
}

output "gold_catalog_name" {
  description = "Gold catalog name."
  value       = local.layer_settings["gold"].catalog_name
}

output "bronze_schema" {
  description = "Bronze schema name."
  value       = local.layer_settings["bronze"].schema_name
}

output "silver_schema" {
  description = "Silver schema name."
  value       = local.layer_settings["silver"].schema_name
}

output "gold_schema" {
  description = "Gold schema name."
  value       = local.layer_settings["gold"].schema_name
}

output "secret_scope_name" {
  description = "Secret scope name to create in Databricks after infrastructure deployment."
  value       = local.secret_scope_name
}

output "layer_principal_client_ids" {
  description = "Client IDs of the layer execution principals."
  value       = local.layer_principal_client_ids
}

output "layer_storage_account_names" {
  description = "Layer storage account names."
  value = {
    for layer, storage in azurerm_storage_account.layer : layer => storage.name
  }
}

output "layer_access_connector_ids" {
  description = "Layer access connector resource IDs."
  value = {
    for layer, connector in azurerm_databricks_access_connector.layer : layer => connector.id
  }
}
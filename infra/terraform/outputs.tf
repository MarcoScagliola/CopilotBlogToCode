output "databricks_workspace_url" {
  description = "Workspace URL used by DAB deploy bridge."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Workspace Azure resource ID used by DAB Azure auth context."
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog_name" {
  description = "Bronze catalog name for DAB variable mapping."
  value       = local.bronze_catalog_name
}

output "silver_catalog_name" {
  description = "Silver catalog name for DAB variable mapping."
  value       = local.silver_catalog_name
}

output "gold_catalog_name" {
  description = "Gold catalog name for DAB variable mapping."
  value       = local.gold_catalog_name
}

output "secret_scope_name" {
  description = "Databricks secret scope name used by runtime jobs."
  value       = local.secret_scope_name
}

output "layer_storage_account_names" {
  description = "Storage account name by medallion layer."
  value = {
    for layer, account in azurerm_storage_account.layer :
    layer => account.name
  }
}

output "layer_access_connector_ids" {
  description = "Databricks access connector resource IDs by layer."
  value = {
    for layer, connector in azurerm_databricks_access_connector.layer :
    layer => connector.id
  }
}

output "layer_principal_client_ids" {
  description = "Layer principal client IDs keyed by layer."
  value       = local.layer_principal_client_ids
}

output "databricks_workspace_url" {
  description = "Workspace URL used as DATABRICKS_HOST."
  value       = "https://${azurerm_databricks_workspace.main.workspace_url}"
}

output "databricks_workspace_resource_id" {
  description = "Workspace resource ID used as DATABRICKS_AZURE_RESOURCE_ID."
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog_name" {
  description = "Bronze catalog name."
  value       = local.layer_catalog_names["bronze"]
}

output "silver_catalog_name" {
  description = "Silver catalog name."
  value       = local.layer_catalog_names["silver"]
}

output "gold_catalog_name" {
  description = "Gold catalog name."
  value       = local.layer_catalog_names["gold"]
}

output "secret_scope_name" {
  description = "Databricks secret scope name."
  value       = local.secret_scope_name
}

output "layer_principal_client_ids" {
  description = "Per-layer principal client IDs."
  value       = local.effective_layer_principal_client_ids
}

output "layer_storage_account_names" {
  description = "Per-layer storage account names."
  value = {
    for k, v in azurerm_storage_account.layer : k => v.name
  }
}

output "layer_access_connector_ids" {
  description = "Per-layer Databricks access connector IDs."
  value = {
    for k, v in azurerm_databricks_access_connector.layer : k => v.id
  }
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "Key Vault ID."
  value       = azurerm_key_vault.main.id
}

output "resource_group_name" {
  description = "Resource group name."
  value       = azurerm_resource_group.main.name
}

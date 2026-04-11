output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = azurerm_resource_group.main.name
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL — use as host in DAB target configuration."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_id" {
  description = "Databricks numeric workspace ID."
  value       = azurerm_databricks_workspace.main.workspace_id
}

output "key_vault_uri" {
  description = "Azure Key Vault URI used for the AKV-backed secret scope."
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_resource_id" {
  description = "Azure Key Vault resource ID."
  value       = azurerm_key_vault.main.id
}

output "storage_account_names" {
  description = "Map of layer → storage account name (use these to verify global uniqueness)."
  value       = { for k, v in azurerm_storage_account.layer : k => v.name }
}

output "storage_dfs_endpoints" {
  description = "Map of layer → ADLS Gen2 DFS endpoint (primary)."
  value       = { for k, v in azurerm_storage_account.layer : k => v.primary_dfs_endpoint }
}

output "service_principal_client_ids" {
  description = "Map of layer → SP client (application) ID. Copy these into DAB variables."
  value       = { for k, v in azuread_application.layer : k => v.client_id }
}

output "unity_catalog_names" {
  description = "Map of layer → Unity Catalog name. Copy these into DAB variables."
  value       = { for k, v in databricks_catalog.layer : k => v.name }
}

output "secret_scope_name" {
  description = "AKV-backed Databricks secret scope name."
  value       = databricks_secret_scope.main.name
}

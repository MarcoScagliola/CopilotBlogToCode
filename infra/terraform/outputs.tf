output "resource_group_name" {
  description = "Resource group name for the deployment."
  value       = azurerm_resource_group.main.name
}

output "key_vault_name" {
  description = "Azure Key Vault name for runtime secret storage."
  value       = azurerm_key_vault.main.name
}

output "secret_scope_name" {
  description = "Expected Databricks secret scope name backed by Key Vault."
  value       = local.secret_scope_name
}

output "databricks_workspace_url" {
  description = "Workspace URL used by Databricks CLI deploy step."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Workspace Azure resource ID used for Azure auth in Databricks CLI."
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog_name" {
  description = "Default bronze catalog name."
  value       = local.catalog_names.bronze
}

output "silver_catalog_name" {
  description = "Default silver catalog name."
  value       = local.catalog_names.silver
}

output "gold_catalog_name" {
  description = "Default gold catalog name."
  value       = local.catalog_names.gold
}

output "layer_storage_account_names" {
  description = "Per-layer storage account names."
  value       = { for layer in local.layers : layer => azurerm_storage_account.layer[layer].name }
}

output "layer_access_connector_ids" {
  description = "Per-layer Databricks access connector resource IDs."
  value       = { for layer in local.layers : layer => azurerm_databricks_access_connector.layer[layer].id }
}

output "layer_principal_client_ids" {
  description = "Per-layer service principal application IDs."
  value       = local.layer_principal_client_ids
}

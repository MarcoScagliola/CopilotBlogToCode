output "resource_group_name" {
  description = "Name of the resource group containing all infrastructure resources."
  value       = azurerm_resource_group.this.name
}

output "databricks_workspace_url" {
  description = "URL of the Databricks workspace."
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Full Azure resource ID of the Databricks workspace. Required by the Databricks CLI for service-principal authentication in CI/CD."
  value       = azurerm_databricks_workspace.this.id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault."
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "secret_scope_name" {
  description = "Name of the AKV-backed Databricks secret scope."
  value       = databricks_secret_scope.akv.name
}

output "storage_account_names" {
  description = "Map of layer → storage account name."
  value       = { for k, v in azurerm_storage_account.layer : k => v.name }
}

output "access_connector_ids" {
  description = "Map of layer → Access Connector resource ID."
  value       = { for k, v in azurerm_databricks_access_connector.layer : k => v.id }
}

output "catalog_names" {
  description = "Map of layer → Unity Catalog catalog name."
  value       = { for k, v in databricks_catalog.layer : k => v.name }
}

output "schema_names" {
  description = "Map of layer → Unity Catalog schema name."
  value       = { for k, v in databricks_schema.layer : k => v.name }
}

output "layer_sp_client_ids" {
  description = "Map of layer → service principal client ID. Use as job runner identities in the DAB."
  value       = local.layer_application_ids
}

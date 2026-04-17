output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
}

output "databricks_workspace_resource_id" {
  value = azurerm_databricks_workspace.this.id
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "secret_scope_name" {
  value = databricks_secret_scope.akv.name
}

output "storage_account_names" {
  value = { for k, v in azurerm_storage_account.layer : k => v.name }
}

output "access_connector_ids" {
  value = { for k, v in azurerm_databricks_access_connector.layer : k => v.id }
}

output "catalog_names" {
  value = { for k, v in databricks_catalog.layer : k => v.name }
}

output "schema_names" {
  value = { for k, v in databricks_schema.layer : k => v.name }
}

output "layer_sp_client_ids" {
  value = local.layer_sp_client_ids
}

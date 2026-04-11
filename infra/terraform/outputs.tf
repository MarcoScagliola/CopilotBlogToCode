output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "layer_storage_account_name" {
  value = { for k, v in azurerm_storage_account.layer : k => v.name }
}

output "layer_sp_client_id" {
  value = { for k, v in azuread_application.layer : k => v.client_id }
}

output "layer_catalog_name" {
  value = { for k, v in databricks_catalog.layer : k => v.name }
}

output "layer_schema_name" {
  value = { for k, v in databricks_schema.layer : k => v.name }
}

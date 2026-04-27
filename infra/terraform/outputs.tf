output "databricks_workspace_url" {
  description = "Databricks workspace URL"
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Databricks workspace Azure resource ID"
  value       = azurerm_databricks_workspace.main.id
}

output "key_vault_id" {
  description = "Azure Key Vault resource ID"
  value       = azurerm_key_vault.platform.id
}

output "key_vault_uri" {
  description = "Azure Key Vault URI"
  value       = azurerm_key_vault.platform.vault_uri
}

output "secret_scope_name" {
  description = "Name of the secret scope to create in Databricks"
  value       = "kv-${var.environment}-scope"
}

# Per-layer outputs
output "bronze_storage_account" {
  description = "Bronze storage account name"
  value       = azurerm_storage_account.layer["bronze"].name
}

output "silver_storage_account" {
  description = "Silver storage account name"
  value       = azurerm_storage_account.layer["silver"].name
}

output "gold_storage_account" {
  description = "Gold storage account name"
  value       = azurerm_storage_account.layer["gold"].name
}

output "bronze_catalog_name" {
  description = "Bronze layer catalog name"
  value       = local.layer_names["bronze"].catalog
}

output "silver_catalog_name" {
  description = "Silver layer catalog name"
  value       = local.layer_names["silver"].catalog
}

output "gold_catalog_name" {
  description = "Gold layer catalog name"
  value       = local.layer_names["gold"].catalog
}

output "bronze_access_connector_id" {
  description = "Bronze Access Connector resource ID"
  value       = azurerm_databricks_access_connector.layer["bronze"].id
}

output "silver_access_connector_id" {
  description = "Silver Access Connector resource ID"
  value       = azurerm_databricks_access_connector.layer["silver"].id
}

output "gold_access_connector_id" {
  description = "Gold Access Connector resource ID"
  value       = azurerm_databricks_access_connector.layer["gold"].id
}

output "bronze_layer_principal_client_id" {
  description = "Bronze layer principal client ID (when layer_sp_mode=create)"
  value       = var.layer_sp_mode == "create" ? azuread_application.layer["bronze"].client_id : var.existing_layer_sp_client_id
  sensitive   = true
}

output "silver_layer_principal_client_id" {
  description = "Silver layer principal client ID (when layer_sp_mode=create)"
  value       = var.layer_sp_mode == "create" ? azuread_application.layer["silver"].client_id : var.existing_layer_sp_client_id
  sensitive   = true
}

output "gold_layer_principal_client_id" {
  description = "Gold layer principal client ID (when layer_sp_mode=create)"
  value       = var.layer_sp_mode == "create" ? azuread_application.layer["gold"].client_id : var.existing_layer_sp_client_id
  sensitive   = true
}

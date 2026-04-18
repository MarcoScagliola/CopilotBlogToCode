output "databricks_workspace_url" {
  description = "Databricks workspace URL for DAB deployment."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Databricks workspace Azure resource ID (required by DAB CLI for authentication)."
  value       = azurerm_databricks_workspace.main.id
}

output "databricks_workspace_id" {
  description = "Databricks workspace ID."
  value       = azurerm_databricks_workspace.main.workspace_id
}

output "layer_principal_client_ids" {
  description = "Layer principal client IDs."
  value = local.create_layer_principals ? {
    bronze = azuread_application.layer["bronze"].client_id
    silver = azuread_application.layer["silver"].client_id
    gold   = azuread_application.layer["gold"].client_id
  } : null
}

output "layer_storage_account_names" {
  description = "Storage account names per layer."
  value       = local.layer_storage_account_names
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.platform.name
}

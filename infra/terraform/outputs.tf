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
  description = "Layer principal client IDs (for configuring Databricks job parameters)."
  value = local.create_layer_principals ? {
    bronze = azuread_application.layer["bronze"].client_id
    silver = azuread_application.layer["silver"].client_id
    gold   = azuread_application.layer["gold"].client_id
  } : null
}

output "layer_principal_object_ids" {
  description = "Layer principal object IDs (for RBAC validation and auditing)."
  value = local.create_layer_principals ? {
    bronze = azuread_service_principal.layer["bronze"].object_id
    silver = azuread_service_principal.layer["silver"].object_id
    gold   = azuread_service_principal.layer["gold"].object_id
  } : null
  sensitive = true
}

output "layer_storage_account_names" {
  description = "Storage account names per layer."
  value       = local.layer_storage_account_names
}

output "layer_storage_account_ids" {
  description = "Storage account resource IDs per layer."
  value = {
    bronze = azurerm_storage_account.layer["bronze"].id
    silver = azurerm_storage_account.layer["silver"].id
    gold   = azurerm_storage_account.layer["gold"].id
  }
}

output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.platform.id
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.platform.name
}

output "databricks_workspace_url" {
  description = "Workspace URL used by the Databricks CLI."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Full Azure resource ID of the Databricks workspace."
  value       = azurerm_databricks_workspace.main.id
}

output "workspace_resource_id" {
  description = "Alias for the Databricks workspace resource ID used by the deploy bridge."
  value       = azurerm_databricks_workspace.main.id
}

output "secret_scope" {
  description = "Databricks secret scope name expected by the bundle."
  value       = local.secret_scope_name
}

output "bronze_catalog" {
  description = "Bronze Unity Catalog catalog name."
  value       = local.bronze_catalog_name
}

output "silver_catalog" {
  description = "Silver Unity Catalog catalog name."
  value       = local.silver_catalog_name
}

output "gold_catalog" {
  description = "Gold Unity Catalog catalog name."
  value       = local.gold_catalog_name
}

output "bronze_schema" {
  description = "Bronze Unity Catalog schema name."
  value       = local.bronze_schema_name
}

output "silver_schema" {
  description = "Silver Unity Catalog schema name."
  value       = local.silver_schema_name
}

output "gold_schema" {
  description = "Gold Unity Catalog schema name."
  value       = local.gold_schema_name
}

output "bronze_storage_account" {
  description = "Bronze storage account name."
  value       = azurerm_storage_account.bronze.name
}

output "silver_storage_account" {
  description = "Silver storage account name."
  value       = azurerm_storage_account.silver.name
}

output "gold_storage_account" {
  description = "Gold storage account name."
  value       = azurerm_storage_account.gold.name
}

output "bronze_access_connector_id" {
  description = "Bronze Databricks access connector resource ID."
  value       = azurerm_databricks_access_connector.bronze.id
}

output "silver_access_connector_id" {
  description = "Silver Databricks access connector resource ID."
  value       = azurerm_databricks_access_connector.silver.id
}

output "gold_access_connector_id" {
  description = "Gold Databricks access connector resource ID."
  value       = azurerm_databricks_access_connector.gold.id
}

output "bronze_principal_client_id" {
  description = "Application (client) ID of the bronze service principal."
  value       = azuread_application.bronze.client_id
}

output "silver_principal_client_id" {
  description = "Application (client) ID of the silver service principal."
  value       = azuread_application.silver.client_id
}

output "gold_principal_client_id" {
  description = "Application (client) ID of the gold service principal."
  value       = azuread_application.gold.client_id
}

output "layer_principal_client_ids" {
  description = "Map of layer principal client IDs for downstream consumers."
  value = {
    bronze = azuread_application.bronze.client_id
    silver = azuread_application.silver.client_id
    gold   = azuread_application.gold.client_id
  }
}

output "layer_storage_account_names" {
  description = "Map of layer storage account names for downstream consumers."
  value = {
    bronze = azurerm_storage_account.bronze.name
    silver = azurerm_storage_account.silver.name
    gold   = azurerm_storage_account.gold.name
  }
}

output "layer_access_connector_ids" {
  description = "Map of layer access connector IDs for downstream consumers."
  value = {
    bronze = azurerm_databricks_access_connector.bronze.id
    silver = azurerm_databricks_access_connector.silver.id
    gold   = azurerm_databricks_access_connector.gold.id
  }
}

output "workspace_name" {
  description = "Databricks workspace name."
  value       = azurerm_databricks_workspace.main.name
}

output "resource_group_name" {
  description = "Canonical resource group name."
  value       = azurerm_resource_group.main.name
}

output "key_vault_name" {
  description = "Canonical Key Vault name."
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault DNS URI used by Databricks secret scopes."
  value       = azurerm_key_vault.main.vault_uri
}
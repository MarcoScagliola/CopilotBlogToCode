output "resource_group_name" {
  description = "Resource group name for generated workload resources."
  value       = azurerm_resource_group.main.name
}

output "key_vault_name" {
  description = "Key Vault name for runtime secret storage."
  value       = azurerm_key_vault.main.name
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL used by deploy bridge for DATABRICKS_HOST."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Databricks workspace Azure resource ID used by deploy bridge for DATABRICKS_AZURE_RESOURCE_ID."
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog" {
  value = local.bronze_catalog
}

output "silver_catalog" {
  value = local.silver_catalog
}

output "gold_catalog" {
  value = local.gold_catalog
}

output "bronze_schema" {
  value = local.bronze_schema
}

output "silver_schema" {
  value = local.silver_schema
}

output "gold_schema" {
  value = local.gold_schema
}

output "secret_scope" {
  value = local.secret_scope
}

output "bronze_principal_client_id" {
  value = local.effective_layer_client_id
}

output "silver_principal_client_id" {
  value = local.effective_layer_client_id
}

output "gold_principal_client_id" {
  value = local.effective_layer_client_id
}

output "bronze_storage_account" {
  value = azurerm_storage_account.bronze.name
}

output "silver_storage_account" {
  value = azurerm_storage_account.silver.name
}

output "gold_storage_account" {
  value = azurerm_storage_account.gold.name
}

output "bronze_access_connector_id" {
  value = azurerm_databricks_access_connector.bronze.id
}

output "silver_access_connector_id" {
  value = azurerm_databricks_access_connector.silver.id
}

output "gold_access_connector_id" {
  value = azurerm_databricks_access_connector.gold.id
}

output "layer_principal_client_ids" {
  value = {
    bronze = local.effective_layer_client_id
    silver = local.effective_layer_client_id
    gold   = local.effective_layer_client_id
  }
}

output "layer_storage_account_names" {
  value = {
    bronze = azurerm_storage_account.bronze.name
    silver = azurerm_storage_account.silver.name
    gold   = azurerm_storage_account.gold.name
  }
}

output "layer_access_connector_ids" {
  value = {
    bronze = azurerm_databricks_access_connector.bronze.id
    silver = azurerm_databricks_access_connector.silver.id
    gold   = azurerm_databricks_access_connector.gold.id
  }
}

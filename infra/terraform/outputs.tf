output "databricks_workspace_url" {
  description = "Azure Databricks workspace URL"
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Azure Databricks workspace resource ID"
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog" {
  value = local.bronze_catalog_name
}

output "silver_catalog" {
  value = local.silver_catalog_name
}

output "gold_catalog" {
  value = local.gold_catalog_name
}

output "bronze_schema" {
  value = "bronze"
}

output "silver_schema" {
  value = "silver"
}

output "gold_schema" {
  value = "gold"
}

output "secret_scope" {
  value = local.secret_scope_name
}

output "bronze_principal_client_id" {
  value = var.client_id
}

output "silver_principal_client_id" {
  value = var.client_id
}

output "gold_principal_client_id" {
  value = var.client_id
}

output "layer_principal_client_ids" {
  value = {
    bronze = var.client_id
    silver = var.client_id
    gold   = var.client_id
  }
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

output "layer_storage_account_names" {
  value = {
    bronze = azurerm_storage_account.bronze.name
    silver = azurerm_storage_account.silver.name
    gold   = azurerm_storage_account.gold.name
  }
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

output "layer_access_connector_ids" {
  value = {
    bronze = azurerm_databricks_access_connector.bronze.id
    silver = azurerm_databricks_access_connector.silver.id
    gold   = azurerm_databricks_access_connector.gold.id
  }
}

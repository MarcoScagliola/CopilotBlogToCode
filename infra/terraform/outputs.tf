output "resource_group_name" {
  description = "Resource group name for the deployment."
  value       = azurerm_resource_group.main.name
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL used by the DAB deploy workflow."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Databricks workspace Azure resource ID used for Azure auth in DAB."
  value       = azurerm_databricks_workspace.main.id
}

output "bronze_catalog" {
  value = var.bronze_catalog
}

output "silver_catalog" {
  value = var.silver_catalog
}

output "gold_catalog" {
  value = var.gold_catalog
}

output "bronze_schema" {
  value = var.bronze_schema
}

output "silver_schema" {
  value = var.silver_schema
}

output "gold_schema" {
  value = var.gold_schema
}

output "secret_scope" {
  value = var.secret_scope
}

output "bronze_principal_client_id" {
  value = local.layer_principal_client_ids.bronze
}

output "silver_principal_client_id" {
  value = local.layer_principal_client_ids.silver
}

output "gold_principal_client_id" {
  value = local.layer_principal_client_ids.gold
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
  value = local.layer_principal_client_ids
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

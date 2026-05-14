output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  value = azurerm_databricks_workspace.main.id
}

output "bronze_catalog_name" {
  value = var.bronze_catalog_name
}

output "silver_catalog_name" {
  value = var.silver_catalog_name
}

output "gold_catalog_name" {
  value = var.gold_catalog_name
}

output "secret_scope_name" {
  value = var.secret_scope_name
}

output "layer_principal_client_ids" {
  value = {
    bronze = local.shared_layer_sp_client_id
    silver = local.shared_layer_sp_client_id
    gold   = local.shared_layer_sp_client_id
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

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
  value = local.bronze_catalog_name
}

output "silver_catalog_name" {
  value = local.silver_catalog_name
}

output "gold_catalog_name" {
  value = local.gold_catalog_name
}

output "bronze_schema" {
  value = local.bronze_schema_name
}

output "silver_schema" {
  value = local.silver_schema_name
}

output "gold_schema" {
  value = local.gold_schema_name
}

output "secret_scope_name" {
  value = local.secret_scope_name
}

output "layer_principal_client_ids" {
  value = {
    bronze = local.bronze_layer_sp_client_id
    silver = local.silver_layer_sp_client_id
    gold   = local.gold_layer_sp_client_id
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

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  value = azurerm_databricks_workspace.main.id
}

output "bronze_catalog_name" {
  value = local.layers.bronze.catalog
}

output "silver_catalog_name" {
  value = local.layers.silver.catalog
}

output "gold_catalog_name" {
  value = local.layers.gold.catalog
}

output "secret_scope_name" {
  value = "kv-${var.environment}-scope"
}

output "layer_storage_account_names" {
  value = {
    for layer, account in azurerm_storage_account.layer :
    layer => account.name
  }
}

output "layer_access_connector_ids" {
  value = {
    for layer, connector in azurerm_databricks_access_connector.layer :
    layer => connector.id
  }
}

output "layer_principal_client_ids" {
  value = var.layer_sp_mode == "create" ? {
    for layer, application in azuread_application.layer :
    layer => application.client_id
  } : {
    for layer, config in local.layers :
    layer => var.existing_layer_sp_client_id
  }
  sensitive = true
}

output "key_vault_id" {
  value = azurerm_key_vault.platform.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.platform.vault_uri
}
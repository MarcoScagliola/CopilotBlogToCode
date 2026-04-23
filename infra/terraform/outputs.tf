output "resource_group_name" {
  description = "Name of the deployed resource group."
  value       = azurerm_resource_group.main.name
}

output "databricks_workspace_url" {
  description = "URL for the Databricks workspace."
  value       = "https://${azurerm_databricks_workspace.main.workspace_url}"
}

output "databricks_workspace_resource_id" {
  description = "Azure resource ID for the Databricks workspace (required for AKV-backed secret scope creation)."
  value       = azurerm_databricks_workspace.main.id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault."
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault (used for AKV-backed secret scope)."
  value       = azurerm_key_vault.main.vault_uri
}

output "secret_scope_name" {
  description = "Databricks secret scope name backed by Key Vault."
  value       = local.secret_scope_name
}

output "layer_storage_account_names" {
  description = "Map of layer to storage account name."
  value = {
    for layer in keys(local.layers) :
    layer => azurerm_storage_account.layer[layer].name
  }
}

output "layer_access_connector_ids" {
  description = "Map of layer to Access Connector resource ID. Empty when enable_access_connectors=false."
  value = var.enable_access_connectors ? {
    for layer in keys(local.layers) :
    layer => azurerm_databricks_access_connector.layer[layer].id
  } : {}
}

output "bronze_catalog_name" {
  description = "Unity Catalog catalog name for the bronze layer."
  value       = local.catalog_names["bronze"]
}

output "silver_catalog_name" {
  description = "Unity Catalog catalog name for the silver layer."
  value       = local.catalog_names["silver"]
}

output "gold_catalog_name" {
  description = "Unity Catalog catalog name for the gold layer."
  value       = local.catalog_names["gold"]
}

output "layer_principal_client_ids" {
  description = "Map of layer to service principal client ID used for job execution."
  sensitive   = true
  value = var.layer_sp_mode == "existing" ? {
    bronze = var.existing_layer_sp_client_id
    silver = var.existing_layer_sp_client_id
    gold   = var.existing_layer_sp_client_id
  } : {
    for layer in keys(local.layers) :
    layer => azuread_application.layer[layer].client_id
  }
}

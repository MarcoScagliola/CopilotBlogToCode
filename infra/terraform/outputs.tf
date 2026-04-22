output "resource_group_name" {
  description = "Platform resource group name."
  value       = azurerm_resource_group.platform.name
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL for DAB deployment."
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Full Azure resource ID of the Databricks workspace."
  value       = azurerm_databricks_workspace.this.id
}

output "layer_storage_account_names" {
  description = "Storage account names by medallion layer."
  value       = { for layer, sa in azurerm_storage_account.layer : layer => sa.name }
}

output "layer_access_connector_ids" {
  description = "Databricks Access Connector resource IDs by medallion layer."
  value = var.enable_access_connectors ? {
    for layer, connector in azurerm_databricks_access_connector.layer : layer => connector.id
  } : {}
}

output "layer_principal_client_ids" {
  description = "Service principal client IDs by medallion layer."
  value       = local.layer_principal_client_ids
}

output "bronze_catalog_name" {
  description = "Unity Catalog name used by Bronze jobs."
  value       = local.layer_catalog_names.bronze
}

output "silver_catalog_name" {
  description = "Unity Catalog name used by Silver jobs."
  value       = local.layer_catalog_names.silver
}

output "gold_catalog_name" {
  description = "Unity Catalog name used by Gold jobs."
  value       = local.layer_catalog_names.gold
}

output "secret_scope_name" {
  description = "Databricks secret scope expected by the sample jobs."
  value       = local.secret_scope_name
}

output "key_vault_name" {
  description = "Azure Key Vault name for runtime secrets."
  value       = azurerm_key_vault.this.name
}

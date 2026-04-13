output "databricks_workspace_resource_id" {
  description = "Azure resource ID for the Databricks workspace."
  value       = azurerm_databricks_workspace.this.id
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL (host) used by Databricks CLI and DAB."
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "secret_scope_name" {
  description = "AKV-backed Databricks secret scope name."
  value       = databricks_secret_scope.key_vault_scope.name
}

output "bronze_catalog_name" {
  description = "Bronze Unity Catalog name."
  value       = databricks_catalog.layers["bronze"].name
}

output "silver_catalog_name" {
  description = "Silver Unity Catalog name."
  value       = databricks_catalog.layers["silver"].name
}

output "gold_catalog_name" {
  description = "Gold Unity Catalog name."
  value       = databricks_catalog.layers["gold"].name
}

output "bronze_sp_application_id" {
  description = "Bronze Microsoft Entra application (client) ID."
  value       = azuread_application.layer_apps["bronze"].client_id
}

output "silver_sp_application_id" {
  description = "Silver Microsoft Entra application (client) ID."
  value       = azuread_application.layer_apps["silver"].client_id
}

output "gold_sp_application_id" {
  description = "Gold Microsoft Entra application (client) ID."
  value       = azuread_application.layer_apps["gold"].client_id
}
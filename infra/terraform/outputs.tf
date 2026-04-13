output "databricks_workspace_url" {
  description = "URL of the provisioned Databricks workspace."
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Full Azure resource ID of the Databricks workspace (required by DAB deploy workflow)."
  value       = azurerm_databricks_workspace.this.id
}

output "secret_scope_name" {
  description = "Name of the Databricks secret scope backed by Key Vault."
  value       = databricks_secret_scope.key_vault_scope.name
}

output "bronze_catalog_name" {
  description = "Unity Catalog name for the Bronze layer."
  value       = databricks_catalog.layers["bronze"].name
}

output "silver_catalog_name" {
  description = "Unity Catalog name for the Silver layer."
  value       = databricks_catalog.layers["silver"].name
}

output "gold_catalog_name" {
  description = "Unity Catalog name for the Gold layer."
  value       = databricks_catalog.layers["gold"].name
}

output "bronze_schema_name" {
  description = "Unity Catalog schema name for the Bronze layer."
  value       = databricks_schema.layers["bronze"].name
}

output "silver_schema_name" {
  description = "Unity Catalog schema name for the Silver layer."
  value       = databricks_schema.layers["silver"].name
}

output "gold_schema_name" {
  description = "Unity Catalog schema name for the Gold layer."
  value       = databricks_schema.layers["gold"].name
}

output "bronze_sp_application_id" {
  description = "Entra Application (client) ID for the Bronze layer service principal."
  value       = azuread_application.layer_apps["bronze"].client_id
}

output "silver_sp_application_id" {
  description = "Entra Application (client) ID for the Silver layer service principal."
  value       = azuread_application.layer_apps["silver"].client_id
}

output "gold_sp_application_id" {
  description = "Entra Application (client) ID for the Gold layer service principal."
  value       = azuread_application.layer_apps["gold"].client_id
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault storing JDBC and other secrets."
  value       = azurerm_key_vault.this.vault_uri
}

output "resource_group_name" {
  description = "Name of the resource group containing all deployed resources."
  value       = azurerm_resource_group.this.name
}

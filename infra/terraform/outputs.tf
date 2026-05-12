# ── Workspace ──────────────────────────────────────────────────────────────────

output "databricks_workspace_url" {
  description = "HTTPS URL of the Databricks workspace."
  value       = "https://${azurerm_databricks_workspace.main.workspace_url}"
}

output "databricks_workspace_resource_id" {
  description = "Full Azure resource ID of the Databricks workspace. Required by the DAB deploy workflow for Azure-based authentication."
  value       = azurerm_databricks_workspace.main.id
}

# ── Per-layer catalog + schema names ──────────────────────────────────────────
# These are logical names consumed by the DAB bundle variables; Unity Catalog
# objects must be created post-deploy (see TODO.md).

output "bronze_catalog" {
  description = "Unity Catalog catalog name for the Bronze layer."
  value       = "bronze"
}

output "silver_catalog" {
  description = "Unity Catalog catalog name for the Silver layer."
  value       = "silver"
}

output "gold_catalog" {
  description = "Unity Catalog catalog name for the Gold layer."
  value       = "gold"
}

output "bronze_schema" {
  description = "Unity Catalog schema name for the Bronze layer."
  value       = "main"
}

output "silver_schema" {
  description = "Unity Catalog schema name for the Silver layer."
  value       = "main"
}

output "gold_schema" {
  description = "Unity Catalog schema name for the Gold layer."
  value       = "main"
}

# ── Per-layer storage account names ───────────────────────────────────────────

output "bronze_storage_account" {
  description = "Storage account name for the Bronze layer."
  value       = azurerm_storage_account.layer["bronze"].name
}

output "silver_storage_account" {
  description = "Storage account name for the Silver layer."
  value       = azurerm_storage_account.layer["silver"].name
}

output "gold_storage_account" {
  description = "Storage account name for the Gold layer."
  value       = azurerm_storage_account.layer["gold"].name
}

# ── Per-layer access connector resource IDs ───────────────────────────────────

output "bronze_access_connector_id" {
  description = "Azure resource ID of the Bronze Access Connector."
  value       = azurerm_databricks_access_connector.layer["bronze"].id
}

output "silver_access_connector_id" {
  description = "Azure resource ID of the Silver Access Connector."
  value       = azurerm_databricks_access_connector.layer["silver"].id
}

output "gold_access_connector_id" {
  description = "Azure resource ID of the Gold Access Connector."
  value       = azurerm_databricks_access_connector.layer["gold"].id
}

# ── Per-layer service principal client IDs ────────────────────────────────────

output "bronze_principal_client_id" {
  description = "Application (client) ID of the Bronze layer service principal."
  value       = local.resolved_layer_client_ids["bronze"]
  sensitive   = true
}

output "silver_principal_client_id" {
  description = "Application (client) ID of the Silver layer service principal."
  value       = local.resolved_layer_client_ids["silver"]
  sensitive   = true
}

output "gold_principal_client_id" {
  description = "Application (client) ID of the Gold layer service principal."
  value       = local.resolved_layer_client_ids["gold"]
  sensitive   = true
}

output "layer_principal_client_ids" {
  description = "Map of layer name to service principal client ID."
  value       = local.resolved_layer_client_ids
  sensitive   = true
}

# ── Secret scope ───────────────────────────────────────────────────────────────

output "secret_scope" {
  description = "Name of the AKV-backed Databricks secret scope to create post-deploy."
  value       = local.secret_scope_name
}

output "secret_scope_name" {
  description = "Alias for secret_scope — matches the DAB bundle variable name."
  value       = local.secret_scope_name
}

# ── Misc ────────────────────────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the deployed resource group."
  value       = azurerm_resource_group.main.name
}

output "layer_storage_account_names" {
  description = "Map of layer name to storage account name."
  value = {
    bronze = azurerm_storage_account.layer["bronze"].name
    silver = azurerm_storage_account.layer["silver"].name
    gold   = azurerm_storage_account.layer["gold"].name
  }
}

output "layer_access_connector_ids" {
  description = "Map of layer name to access connector resource ID."
  value = {
    bronze = azurerm_databricks_access_connector.layer["bronze"].id
    silver = azurerm_databricks_access_connector.layer["silver"].id
    gold   = azurerm_databricks_access_connector.layer["gold"].id
  }
}

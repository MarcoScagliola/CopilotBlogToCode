# ---------------------------------------------------------------------------
# Workspace connectivity
# ---------------------------------------------------------------------------

output "databricks_workspace_url" {
  description = "HTTPS URL of the Databricks workspace. Used by the DAB deploy workflow to set DATABRICKS_HOST."
  value       = "https://${azurerm_databricks_workspace.main.workspace_url}"
}

output "databricks_workspace_resource_id" {
  description = "Full Azure resource ID of the Databricks workspace. Required by the DAB deploy bridge for Azure SP authentication (DATABRICKS_AZURE_RESOURCE_ID)."
  value       = azurerm_databricks_workspace.main.id
}

# ---------------------------------------------------------------------------
# Per-layer catalog and schema identifiers
# ---------------------------------------------------------------------------

output "bronze_catalog" {
  description = "Unity Catalog catalog name for the Bronze layer."
  value       = local.catalogs["bronze"]
}

output "silver_catalog" {
  description = "Unity Catalog catalog name for the Silver layer."
  value       = local.catalogs["silver"]
}

output "gold_catalog" {
  description = "Unity Catalog catalog name for the Gold layer."
  value       = local.catalogs["gold"]
}

output "bronze_schema" {
  description = "Unity Catalog schema name for the Bronze layer."
  value       = local.schemas["bronze"]
}

output "silver_schema" {
  description = "Unity Catalog schema name for the Silver layer."
  value       = local.schemas["silver"]
}

output "gold_schema" {
  description = "Unity Catalog schema name for the Gold layer."
  value       = local.schemas["gold"]
}

# ---------------------------------------------------------------------------
# Per-layer storage account names
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Per-layer Access Connector resource IDs
# ---------------------------------------------------------------------------

output "bronze_access_connector_id" {
  description = "Full Azure resource ID of the Bronze Databricks Access Connector."
  value       = azurerm_databricks_access_connector.layer["bronze"].id
}

output "silver_access_connector_id" {
  description = "Full Azure resource ID of the Silver Databricks Access Connector."
  value       = azurerm_databricks_access_connector.layer["silver"].id
}

output "gold_access_connector_id" {
  description = "Full Azure resource ID of the Gold Databricks Access Connector."
  value       = azurerm_databricks_access_connector.layer["gold"].id
}

# ---------------------------------------------------------------------------
# Per-layer service principal client IDs
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Secret scope name
# ---------------------------------------------------------------------------

output "secret_scope" {
  description = "Databricks secret scope name backed by the Azure Key Vault. Used by entrypoints to read runtime secrets."
  value       = local.secret_scope_name
}

# ---------------------------------------------------------------------------
# Resource group
# ---------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the Azure resource group containing all workload resources."
  value       = azurerm_resource_group.main.name
}

# ---------------------------------------------------------------------------
# Bridge-compatible map outputs
# The deploy bridge (deploy_dab.py) resolves optional per-layer values via
# OPTIONAL_MAP_KEYS which expect a map output keyed by layer name.
# ---------------------------------------------------------------------------

output "layer_principal_client_ids" {
  description = "Map of layer name to service principal client ID. Used by the deploy bridge OPTIONAL_MAP_KEYS resolution."
  sensitive   = true
  value = {
    for layer in toset(["bronze", "silver", "gold"]) :
    layer => local.resolved_layer_client_ids[layer]
  }
}

output "layer_storage_account_names" {
  description = "Map of layer name to storage account name. Used by the deploy bridge OPTIONAL_MAP_KEYS resolution."
  value = {
    for layer in toset(["bronze", "silver", "gold"]) :
    layer => local.storage_accounts[layer]
  }
}

output "layer_access_connector_ids" {
  description = "Map of layer name to Databricks Access Connector resource ID. Used by the deploy bridge OPTIONAL_MAP_KEYS resolution."
  value = {
    for layer in toset(["bronze", "silver", "gold"]) :
    layer => azurerm_databricks_access_connector.layer[layer].id
  }
}

# Bridge-compatible flat aliases for catalog and scope names.
# The deploy bridge OPTIONAL_FLAT_KEYS searches for these specific names.
output "bronze_catalog_name" {
  description = "Alias for bronze_catalog — searched by the deploy bridge OPTIONAL_FLAT_KEYS."
  value       = local.catalogs["bronze"]
}

output "silver_catalog_name" {
  description = "Alias for silver_catalog — searched by the deploy bridge OPTIONAL_FLAT_KEYS."
  value       = local.catalogs["silver"]
}

output "gold_catalog_name" {
  description = "Alias for gold_catalog — searched by the deploy bridge OPTIONAL_FLAT_KEYS."
  value       = local.catalogs["gold"]
}

output "secret_scope_name" {
  description = "Alias for secret_scope — searched by the deploy bridge OPTIONAL_FLAT_KEYS."
  value       = local.secret_scope_name
}

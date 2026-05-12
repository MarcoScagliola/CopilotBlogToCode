# ---------------------------------------------------------------------------
# Workspace
# ---------------------------------------------------------------------------

output "databricks_workspace_url" {
  description = "Databricks workspace URL. Used by deploy-dab.yml to set DATABRICKS_HOST."
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_resource_id" {
  description = "Full Azure resource ID of the Databricks workspace. Required for Azure SP auth in DAB."
  value       = azurerm_databricks_workspace.main.id
}

# ---------------------------------------------------------------------------
# Per-layer catalog and schema (names — not provisioned by Terraform)
# The bundle's setup job creates the UC objects; Terraform exports the names
# so the bundle doesn't need to recompute them.
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Per-layer storage
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

output "layer_storage_account_names" {
  description = "Map of layer → storage account name."
  value = {
    for layer in local.layers :
    layer => azurerm_storage_account.layer[layer].name
  }
}

# ---------------------------------------------------------------------------
# Per-layer access connectors
# ---------------------------------------------------------------------------

output "bronze_access_connector_id" {
  description = "Resource ID of the Bronze Access Connector."
  value       = azurerm_databricks_access_connector.layer["bronze"].id
}

output "silver_access_connector_id" {
  description = "Resource ID of the Silver Access Connector."
  value       = azurerm_databricks_access_connector.layer["silver"].id
}

output "gold_access_connector_id" {
  description = "Resource ID of the Gold Access Connector."
  value       = azurerm_databricks_access_connector.layer["gold"].id
}

output "layer_access_connector_ids" {
  description = "Map of layer → access connector resource ID."
  value = {
    for layer in local.layers :
    layer => azurerm_databricks_access_connector.layer[layer].id
  }
}

# ---------------------------------------------------------------------------
# Per-layer principal client IDs (sensitive — used by bundle for auth context)
# ---------------------------------------------------------------------------

output "bronze_principal_client_id" {
  description = "Client ID of the Bronze layer service principal."
  value       = local.resolved_layer_client_ids["bronze"]
  sensitive   = true
}

output "silver_principal_client_id" {
  description = "Client ID of the Silver layer service principal."
  value       = local.resolved_layer_client_ids["silver"]
  sensitive   = true
}

output "gold_principal_client_id" {
  description = "Client ID of the Gold layer service principal."
  value       = local.resolved_layer_client_ids["gold"]
  sensitive   = true
}

output "layer_principal_client_ids" {
  description = "Map of layer → service principal client ID. Sensitive."
  value = {
    for layer in local.layers :
    layer => local.resolved_layer_client_ids[layer]
  }
  sensitive = true
}

# ---------------------------------------------------------------------------
# Key Vault / secret scope
# ---------------------------------------------------------------------------

output "secret_scope" {
  description = "Name of the Key Vault-backed Databricks secret scope."
  value       = local.secret_scope_name
}

output "secret_scope_name" {
  description = "Alias for secret_scope — used by the deploy bridge."
  value       = local.secret_scope_name
}

# ---------------------------------------------------------------------------
# Infrastructure metadata
# ---------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group containing all workload resources."
  value       = azurerm_resource_group.main.name
}

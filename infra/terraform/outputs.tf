output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.blg.name
}

output "resource_group_id" {
  description = "ID of the Azure Resource Group"
  value       = azurerm_resource_group.blg.id
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL"
  value       = "https://${azurerm_databricks_workspace.blg.workspace_url}"
  sensitive   = false
}

output "databricks_workspace_resource_id" {
  description = "Databricks workspace resource ID"
  value       = azurerm_databricks_workspace.blg.id
}

output "databricks_workspace_id" {
  description = "Databricks workspace ID (numeric)"
  value       = azurerm_databricks_workspace.blg.workspace_id
  sensitive   = false
}

# ================================================================================
# Storage Accounts
# ================================================================================

output "bronze_storage_account_name" {
  description = "Name of Bronze storage account"
  value       = azurerm_storage_account.bronze.name
}

output "bronze_storage_account_id" {
  description = "ID of Bronze storage account"
  value       = azurerm_storage_account.bronze.id
}

output "silver_storage_account_name" {
  description = "Name of Silver storage account"
  value       = azurerm_storage_account.silver.name
}

output "silver_storage_account_id" {
  description = "ID of Silver storage account"
  value       = azurerm_storage_account.silver.id
}

output "gold_storage_account_name" {
  description = "Name of Gold storage account"
  value       = azurerm_storage_account.gold.name
}

output "gold_storage_account_id" {
  description = "ID of Gold storage account"
  value       = azurerm_storage_account.gold.id
}

# ================================================================================
# Key Vault
# ================================================================================

output "key_vault_id" {
  description = "ID of Key Vault"
  value       = azurerm_key_vault.blg.id
}

output "key_vault_name" {
  description = "Name of Key Vault"
  value       = azurerm_key_vault.blg.name
}

output "key_vault_uri" {
  description = "URI of Key Vault"
  value       = azurerm_key_vault.blg.vault_uri
}

# ================================================================================
# Service Principals
# ================================================================================

output "bronze_sp_client_id" {
  description = "Client ID (App ID) of Bronze service principal"
  value       = azuread_service_principal.bronze.client_id
  sensitive   = false
}

output "bronze_sp_object_id" {
  description = "Object ID of Bronze service principal"
  value       = azuread_service_principal.bronze.object_id
  sensitive   = false
}

output "silver_sp_client_id" {
  description = "Client ID (App ID) of Silver service principal"
  value       = azuread_service_principal.silver.client_id
  sensitive   = false
}

output "silver_sp_object_id" {
  description = "Object ID of Silver service principal"
  value       = azuread_service_principal.silver.object_id
  sensitive   = false
}

output "gold_sp_client_id" {
  description = "Client ID (App ID) of Gold service principal"
  value       = azuread_service_principal.gold.client_id
  sensitive   = false
}

output "gold_sp_object_id" {
  description = "Object ID of Gold service principal"
  value       = azuread_service_principal.gold.object_id
  sensitive   = false
}

# ================================================================================
# Access Connectors
# ================================================================================

output "access_connector_bronze_id" {
  description = "Resource ID of Bronze access connector"
  value       = azurerm_databricks_access_connector.bronze.id
}

output "access_connector_silver_id" {
  description = "Resource ID of Silver access connector"
  value       = azurerm_databricks_access_connector.silver.id
}

output "access_connector_gold_id" {
  description = "Resource ID of Gold access connector"
  value       = azurerm_databricks_access_connector.gold.id
}

# ================================================================================
# UC Storage Credentials
# ================================================================================

output "uc_credential_bronze_id" {
  description = "UC storage credential ID for Bronze"
  value       = databricks_storage_credential.bronze.id
}

output "uc_credential_silver_id" {
  description = "UC storage credential ID for Silver"
  value       = databricks_storage_credential.silver.id
}

output "uc_credential_gold_id" {
  description = "UC storage credential ID for Gold"
  value       = databricks_storage_credential.gold.id
}

# ================================================================================
# UC External Locations
# ================================================================================

output "uc_external_location_bronze_url" {
  description = "URL of Bronze external location"
  value       = databricks_external_location.bronze.url
}

output "uc_external_location_silver_url" {
  description = "URL of Silver external location"
  value       = databricks_external_location.silver.url
}

output "uc_external_location_gold_url" {
  description = "URL of Gold external location"
  value       = databricks_external_location.gold.url
}

# ================================================================================
# UC Catalogs
# ================================================================================

output "uc_catalog_bronze" {
  description = "Bronze UC catalog name"
  value       = databricks_catalog.bronze.name
}

output "uc_catalog_silver" {
  description = "Silver UC catalog name"
  value       = databricks_catalog.silver.name
}

output "uc_catalog_gold" {
  description = "Gold UC catalog name"
  value       = databricks_catalog.gold.name
}

# ================================================================================
# UC Schemas
# ================================================================================

output "uc_schema_bronze" {
  description = "Bronze UC schema name"
  value       = databricks_schema.bronze.name
}

output "uc_schema_silver" {
  description = "Silver UC schema name"
  value       = databricks_schema.silver.name
}

output "uc_schema_gold" {
  description = "Gold UC schema name"
  value       = databricks_schema.gold.name
}

# ================================================================================
# AKV Secret Scope
# ================================================================================

output "secret_scope_name" {
  description = "Name of Databricks AKV-backed secret scope"
  value       = databricks_secret_scope.akv.name
}

# ================================================================================
# Summary Output (for DAB integration)
# ================================================================================

output "dab_variables" {
  description = "Variables for DAB integration (JSON map)"
  value = {
    workspace_host         = "https://${azurerm_databricks_workspace.blg.workspace_url}"
    bronze_catalog         = databricks_catalog.bronze.name
    silver_catalog         = databricks_catalog.silver.name
    gold_catalog           = databricks_catalog.gold.name
    bronze_schema          = databricks_schema.bronze.name
    silver_schema          = databricks_schema.silver.name
    gold_schema            = databricks_schema.gold.name
    bronze_sp_client_id    = azuread_service_principal.bronze.client_id
    silver_sp_client_id    = azuread_service_principal.silver.client_id
    gold_sp_client_id      = azuread_service_principal.gold.client_id
    secret_scope           = databricks_secret_scope.akv.name
  }
  sensitive = false
}

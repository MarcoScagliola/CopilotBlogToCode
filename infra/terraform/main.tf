resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = local.azure_region_normalized
}

resource "azurerm_storage_account" "bronze" {
  name                            = local.bronze_storage_account_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  shared_access_key_enabled       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_account" "silver" {
  name                            = local.silver_storage_account_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  shared_access_key_enabled       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_account" "gold" {
  name                            = local.gold_storage_account_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  shared_access_key_enabled       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name               = local.bronze_filesystem_name
  storage_account_id = azurerm_storage_account.bronze.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "silver" {
  name               = local.silver_filesystem_name
  storage_account_id = azurerm_storage_account.silver.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "gold" {
  name               = local.gold_filesystem_name
  storage_account_id = azurerm_storage_account.gold.id
}

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  rbac_authorization_enabled = true
}

resource "azurerm_databricks_workspace" "main" {
  name                        = local.workspace_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = "premium"
  managed_resource_group_name = local.managed_resource_group_name
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = local.bronze_access_connector_name
  resource_group_name  = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = local.silver_access_connector_name
  resource_group_name  = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = local.gold_access_connector_name
  resource_group_name  = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azuread_application" "bronze" {
  display_name = local.bronze_application_name
}

resource "azuread_application" "silver" {
  display_name = local.silver_application_name
}

resource "azuread_application" "gold" {
  display_name = local.gold_application_name
}

resource "azuread_service_principal" "bronze" {
  client_id = azuread_application.bronze.client_id
}

resource "azuread_service_principal" "silver" {
  client_id = azuread_application.silver.client_id
}

resource "azuread_service_principal" "gold" {
  client_id = azuread_application.gold.client_id
}

resource "azurerm_role_assignment" "deployment_key_vault_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}

resource "azurerm_role_assignment" "bronze_key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.bronze.object_id
}

resource "azurerm_role_assignment" "silver_key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.silver.object_id
}

resource "azurerm_role_assignment" "gold_key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.gold.object_id
}

resource "azurerm_role_assignment" "bronze_access_connector_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

resource "azurerm_role_assignment" "silver_access_connector_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.silver.identity[0].principal_id
}

resource "azurerm_role_assignment" "gold_access_connector_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.gold.identity[0].principal_id
}
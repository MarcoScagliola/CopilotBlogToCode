data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_storage_account" "bronze" {
  name                            = local.bronze_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = var.enable_shared_key
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_account" "silver" {
  name                            = local.silver_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = var.enable_shared_key
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_account" "gold" {
  name                            = local.gold_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = var.enable_shared_key
  allow_nested_items_to_be_public = false
}

resource "azurerm_key_vault" "main" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
}

resource "azurerm_databricks_workspace" "main" {
  name                                  = local.workspace_name
  resource_group_name                   = azurerm_resource_group.main.name
  location                              = azurerm_resource_group.main.location
  sku                                   = "premium"
  infrastructure_encryption_enabled     = true
  public_network_access_enabled         = true
  network_security_group_rules_required = "NoAzureDatabricksRules"
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = "dac-${var.workload}-bronze-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = "dac-${var.workload}-silver-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = "dac-${var.workload}-gold-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "bronze_connector_blob_contributor" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

resource "azurerm_role_assignment" "silver_connector_blob_contributor" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.silver.identity[0].principal_id
}

resource "azurerm_role_assignment" "gold_connector_blob_contributor" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.gold.identity[0].principal_id
}

resource "azurerm_role_assignment" "deployment_sp_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}
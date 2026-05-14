resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region
}

resource "azurerm_storage_account" "bronze" {
  name                            = local.bronze_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_account" "silver" {
  name                            = local.silver_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_account" "gold" {
  name                            = local.gold_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
}

resource "azurerm_key_vault" "main" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  public_network_access_enabled = true
}

resource "azurerm_databricks_workspace" "main" {
  name                                  = local.workspace_name
  resource_group_name                   = azurerm_resource_group.main.name
  location                              = azurerm_resource_group.main.location
  sku                                   = "premium"
  public_network_access_enabled         = true
  infrastructure_encryption_enabled     = false
  network_security_group_rules_required = "NoAzureDatabricksRules"
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = "ac-bronze-${local.workload}-${local.environment}-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = "ac-silver-${local.workload}-${local.environment}-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = "ac-gold-${local.workload}-${local.environment}-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "bronze_storage" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

resource "azurerm_role_assignment" "silver_storage" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.silver.identity[0].principal_id
}

resource "azurerm_role_assignment" "gold_storage" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.gold.identity[0].principal_id
}

resource "azurerm_role_assignment" "key_vault_secret_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_databricks_workspace.main.managed_resource_group_id != "" ? azurerm_databricks_access_connector.bronze.identity[0].principal_id : azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

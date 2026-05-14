resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region
}

resource "azurerm_storage_account" "bronze" {
  name                     = local.bronze_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_account" "silver" {
  name                     = local.silver_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_account" "gold" {
  name                     = local.gold_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
}

resource "azurerm_key_vault" "main" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = true
}

resource "azurerm_key_vault_access_policy" "deployment_sp" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.sp_object_id

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Recover",
    "Purge",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Purge",
  ]
}

resource "azurerm_databricks_workspace" "main" {
  name                        = local.workspace_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = "premium"
  managed_resource_group_name = substr("rg-dbw-${var.workload}-${var.environment}-${local.region_abbrev}", 0, 90)
  public_network_access_enabled = false
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = "ac-${var.workload}-${var.environment}-bronze-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = "ac-${var.workload}-${var.environment}-silver-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = "ac-${var.workload}-${var.environment}-gold-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "bronze_storage_contributor" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

resource "azurerm_role_assignment" "silver_storage_contributor" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.silver.identity[0].principal_id
}

resource "azurerm_role_assignment" "gold_storage_contributor" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.gold.identity[0].principal_id
}

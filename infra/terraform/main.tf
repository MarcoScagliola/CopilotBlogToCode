resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
  tags     = local.merged_tags
}

resource "azurerm_storage_account" "bronze" {
  name                            = local.bronze_storage_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  is_hns_enabled                  = true
  shared_access_key_enabled       = var.shared_access_key_enabled
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = merge(local.merged_tags, { layer = "bronze" })
}

resource "azurerm_storage_account" "silver" {
  name                            = local.silver_storage_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  is_hns_enabled                  = true
  shared_access_key_enabled       = var.shared_access_key_enabled
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = merge(local.merged_tags, { layer = "silver" })
}

resource "azurerm_storage_account" "gold" {
  name                            = local.gold_storage_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  is_hns_enabled                  = true
  shared_access_key_enabled       = var.shared_access_key_enabled
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = merge(local.merged_tags, { layer = "gold" })
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
  tags                          = local.merged_tags
}

resource "azurerm_databricks_workspace" "main" {
  name                        = local.workspace_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = "premium"
  managed_resource_group_name = "rg-${local.workspace_name}-mrg"
  public_network_access_enabled = true
  tags                        = local.merged_tags
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = "ac-${var.workload}-${var.environment}-bronze-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.merged_tags, { layer = "bronze" })
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = "ac-${var.workload}-${var.environment}-silver-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.merged_tags, { layer = "silver" })
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = "ac-${var.workload}-${var.environment}-gold-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.merged_tags, { layer = "gold" })
}

resource "azurerm_role_assignment" "deployment_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
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

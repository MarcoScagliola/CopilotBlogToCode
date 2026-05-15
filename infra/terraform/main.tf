resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region

  tags = {
    workload    = var.workload
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_account" "bronze" {
  name                     = local.bronze_storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  shared_access_key_enabled = var.enable_shared_key
  min_tls_version          = "TLS1_2"

  tags = {
    layer       = "bronze"
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_storage_account" "silver" {
  name                     = local.silver_storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  shared_access_key_enabled = var.enable_shared_key
  min_tls_version          = "TLS1_2"

  tags = {
    layer       = "silver"
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_storage_account" "gold" {
  name                     = local.gold_storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  shared_access_key_enabled = var.enable_shared_key
  min_tls_version          = "TLS1_2"

  tags = {
    layer       = "gold"
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_key_vault" "main" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = true

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_databricks_workspace" "main" {
  name                = local.workspace_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = local.bronze_access_connector_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    layer       = "bronze"
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = local.silver_access_connector_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    layer       = "silver"
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = local.gold_access_connector_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    layer       = "gold"
    workload    = var.workload
    environment = var.environment
  }
}

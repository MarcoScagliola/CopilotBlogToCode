resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_storage_account" "bronze" {
  name                     = local.bronze_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = "bronze"
  }
}

resource "azurerm_storage_account" "silver" {
  name                     = local.silver_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = "silver"
  }
}

resource "azurerm_storage_account" "gold" {
  name                     = local.gold_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = "gold"
  }
}

resource "azurerm_databricks_workspace" "main" {
  name                = local.databricks_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = "adb-ac-${local.workload_sanitized}-${local.environment_short}-bronze-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = "adb-ac-${local.workload_sanitized}-${local.environment_short}-silver-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = "adb-ac-${local.workload_sanitized}-${local.environment_short}-gold-${local.region_abbrev}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
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

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

resource "azuread_application" "bronze" {
  display_name = "sp-${local.workload_sanitized}-${local.environment_short}-bronze"
}

resource "azuread_application" "silver" {
  display_name = "sp-${local.workload_sanitized}-${local.environment_short}-silver"
}

resource "azuread_application" "gold" {
  display_name = "sp-${local.workload_sanitized}-${local.environment_short}-gold"
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

resource "azurerm_role_assignment" "kv_secrets_officer_deployment" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}

resource "azurerm_role_assignment" "kv_secrets_user_bronze" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.bronze_layer_sp_object_id
}

resource "azurerm_role_assignment" "kv_secrets_user_silver" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.silver_layer_sp_object_id
}

resource "azurerm_role_assignment" "kv_secrets_user_gold" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.gold_layer_sp_object_id
}

resource "azurerm_role_assignment" "storage_bronze_layer" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_silver_layer" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.silver.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_gold_layer" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.gold.identity[0].principal_id
}

resource "azurerm_resource_group" "platform" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layer_settings

  name                     = local.storage_account_names[each.key]
  resource_group_name      = azurerm_resource_group.platform.name
  location                 = azurerm_resource_group.platform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layer_settings

  name                = local.access_connector_names[each.key]
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "access_connector_storage" {
  for_each = local.layer_settings

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azuread_application" "layer" {
  for_each = local.create_layer_principals ? local.layer_settings : {}

  display_name = "sp-${var.workload}-${var.environment}-${each.key}-${local.azure_region_abbrev}"
}

resource "azuread_service_principal" "layer" {
  for_each = local.create_layer_principals ? local.layer_settings : {}

  client_id = azuread_application.layer[each.key].client_id
}

resource "azurerm_key_vault" "platform" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.platform.location
  resource_group_name        = azurerm_resource_group.platform.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.sp_object_id
}

resource "azurerm_role_assignment" "layer_storage_rbac" {
  for_each = local.layer_settings

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.layer_principal_object_ids[each.key]
}

resource "azurerm_role_assignment" "layer_keyvault_rbac" {
  for_each = local.layer_settings

  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.layer_principal_object_ids[each.key]
}

resource "azurerm_databricks_workspace" "platform" {
  name                        = local.databricks_workspace_name
  resource_group_name         = azurerm_resource_group.platform.name
  location                    = azurerm_resource_group.platform.location
  sku                         = "premium"
  managed_resource_group_name = "rg-${var.workload}-${var.environment}-dbw-${local.azure_region_abbrev}"
}

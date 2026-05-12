data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region
  tags     = local.common_tags
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                      = local.storage_name[each.key]
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  is_hns_enabled            = true
  shared_access_key_enabled = true

  tags = merge(local.common_tags, { layer = each.key })
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = local.access_connector_name[each.key]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.common_tags, { layer = each.key })
}

resource "azurerm_role_assignment" "connector_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azuread_application" "layer" {
  for_each = local.create_layer_sps ? local.layers : toset([])

  display_name = local.sp_display_name[each.key]
}

resource "azuread_service_principal" "layer" {
  for_each = local.create_layer_sps ? local.layers : toset([])

  client_id = azuread_application.layer[each.key].client_id
}

resource "azurerm_role_assignment" "layer_sp_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.resolved_layer_object_ids[each.key]
}

resource "azurerm_key_vault" "main" {
  name                = local.kv_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  tags = local.common_tags
}

resource "azurerm_key_vault_access_policy" "deployment_sp" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.sp_object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
}

resource "azurerm_key_vault_access_policy" "layer_sp" {
  for_each = local.layers

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.resolved_layer_object_ids[each.key]

  secret_permissions = ["Get", "List"]
}

resource "azurerm_databricks_workspace" "main" {
  name                = local.workspace_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  custom_parameters {
    no_public_ip = true
  }

  tags = local.common_tags
}

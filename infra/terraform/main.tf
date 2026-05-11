# Resource definitions for the secure medallion pattern. Per-layer isolation
# is enforced at identity, storage, and compute boundaries.

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region
  tags     = local.common_tags
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layer_storage_names

  name                     = each.value
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  # Keep enabled for provider compatibility during initial create/poll.
  shared_access_key_enabled = var.enable_storage_shared_key

  min_tls_version = "TLS1_2"

  tags = merge(local.common_tags, {
    layer = each.key
  })
}

resource "azurerm_storage_container" "layer" {
  for_each = azurerm_storage_account.layer

  name                  = "data"
  storage_account_name  = each.value.name
  container_access_type = "private"
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = "dbac-${each.key}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.common_tags, {
    layer = each.key
  })
}

resource "azurerm_role_assignment" "layer_access_connector_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azuread_application" "layer" {
  for_each = local.layer_sp_keys

  display_name = "sp-${each.key}-${local.name_suffix}"
}

resource "azuread_service_principal" "layer" {
  for_each = local.layer_sp_keys

  client_id = azuread_application.layer[each.key].client_id
}

resource "azuread_service_principal_password" "layer" {
  for_each = local.layer_sp_keys

  service_principal_id = azuread_service_principal.layer[each.key].id
}

locals {
  effective_layer_principal_object_ids = local.should_create_layer_sps ? {
    for k, v in azuread_service_principal.layer : k => v.object_id
    } : {
    for layer in local.layers : layer => coalesce(var.existing_layer_sp_object_id, var.sp_object_id)
  }

  effective_layer_principal_client_ids = local.should_create_layer_sps ? {
    for k, v in azuread_service_principal.layer : k => v.client_id
    } : {
    for layer in local.layers : layer => coalesce(var.existing_layer_sp_client_id, var.client_id)
  }
}

resource "azurerm_role_assignment" "layer_sp_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.effective_layer_principal_object_ids[each.key]
}

resource "azurerm_key_vault" "main" {
  name                = local.kv_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = var.tenant_id

  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = local.common_tags
}

resource "azurerm_role_assignment" "kv_deployer_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}

resource "azurerm_role_assignment" "kv_layer_user" {
  for_each = local.layers

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.effective_layer_principal_object_ids[each.key]
}

resource "azurerm_databricks_workspace" "main" {
  name                = local.workspace_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  tags = local.common_tags
}

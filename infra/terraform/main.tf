data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "platform" {
  name     = "rg-${local.base_name}-platform"
  location = var.azure_region
}

resource "random_string" "keyvault_suffix" {
  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_key_vault" "platform" {
  name                = "kv-${local.base_name}-${random_string.keyvault_suffix.result}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tenant_id           = var.azure_tenant_id
  sku_name            = "standard"

  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "Set", "List", "Delete", "Recover", "Purge"]
  }
}

resource "azurerm_databricks_workspace" "main" {
  name                = "dbw-${local.base_name}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  sku                 = "premium"

  managed_resource_group_name = "rg-${local.base_name}-dbw-managed"
}

resource "azurerm_storage_account" "layer" {
  for_each = toset(local.layer_names)

  name                     = local.layer_storage_account_names[each.key]
  resource_group_name      = azurerm_resource_group.platform.name
  location                 = azurerm_resource_group.platform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"

  shared_access_key_enabled = true
}

resource "azurerm_storage_container" "layer" {
  for_each = toset(local.layer_names)

  name                  = each.key
  storage_account_id    = azurerm_storage_account.layer[each.key].id
  container_access_type = "private"
}

resource "azuread_application" "layer" {
  for_each = local.create_layer_principals ? toset(local.layer_names) : []

  display_name = "app-${local.base_name}-${each.key}"
}

resource "azuread_service_principal" "layer" {
  for_each = local.create_layer_principals ? toset(local.layer_names) : []

  client_id = azuread_application.layer[each.key].client_id
}

resource "azurerm_role_assignment" "layer_blob_owner" {
  for_each = toset(local.layer_names)

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Owner"
  principal_type       = "ServicePrincipal"
  principal_id         = local.create_layer_principals ? azuread_service_principal.layer[each.key].object_id : var.existing_layer_sp_object_id

  skip_service_principal_aad_check = true
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  for_each = toset(local.layer_names)

  name         = "${each.key}-storage-account-name"
  value        = azurerm_storage_account.layer[each.key].name
  key_vault_id = azurerm_key_vault.platform.id
}

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region
}

resource "azurerm_databricks_workspace" "main" {
  name                = local.databricks_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  public_network_access_enabled = false
}

resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  purge_protection_enabled   = false
  soft_delete_retention_days = 90
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                            = local.layer_storage_names[each.key]
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = "ac-${var.workload}-${var.environment}-${each.key}-${local.azure_region_abbr}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azuread_application" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : toset([])

  display_name = "sp-${var.workload}-${var.environment}-${each.key}-${local.azure_region_abbr}"
}

resource "azuread_service_principal" "layer" {
  for_each = var.layer_sp_mode == "create" ? azuread_application.layer : {}

  client_id = each.value.client_id
}

locals {
  layer_principal_client_ids = var.layer_sp_mode == "create" ? {
    for layer, sp in azuread_service_principal.layer :
    layer => sp.client_id
  } : {
    for layer in local.layers :
    layer => var.existing_layer_sp_client_id
  }

  layer_principal_object_ids = var.layer_sp_mode == "create" ? {
    for layer, sp in azuread_service_principal.layer :
    layer => sp.object_id
  } : {
    for layer in local.layers :
    layer => var.existing_layer_sp_object_id
  }

  unique_layer_principal_object_ids = toset(values(local.layer_principal_object_ids))
}

resource "azurerm_role_assignment" "layer_storage_blob_contributor" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.layer_principal_object_ids[each.key]
}

resource "azurerm_role_assignment" "layer_key_vault_secrets_user" {
  for_each = local.unique_layer_principal_object_ids

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "access_connector_storage_contributor" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_resource_group" "platform" {
  name     = local.rg_name
  location = var.azure_region
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layer_map

  name                     = substr("${each.value.storage_account_name}${random_string.suffix.result}", 0, 24)
  resource_group_name      = azurerm_resource_group.platform.name
  location                 = azurerm_resource_group.platform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_databricks_workspace" "this" {
  name                        = local.databricks_workspace
  resource_group_name         = azurerm_resource_group.platform.name
  location                    = azurerm_resource_group.platform.location
  sku                         = "premium"
  managed_resource_group_name = local.databricks_managed_rg

  custom_parameters {
    no_public_ip = true
  }
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layer_map

  name                = each.value.connector_name
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault" "platform" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.platform.location
  resource_group_name           = azurerm_resource_group.platform.name
  tenant_id                     = var.azure_tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = var.key_vault_enable_purge_protection
  soft_delete_retention_days    = 7
  public_network_access_enabled = true
}

resource "azuread_application" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layer_map : {}

  display_name = "app-${var.workload}-${var.environment}-${each.key}"
}

resource "azuread_service_principal" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layer_map : {}

  client_id = azuread_application.layer[each.key].client_id
}

resource "azuread_service_principal_password" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layer_map : {}

  service_principal_id = azuread_service_principal.layer[each.key].id
}

locals {
  layer_principal_object_ids = {
    for layer in local.layer_names :
    layer => (
      var.layer_sp_mode == "create"
      ? azuread_service_principal.layer[layer].object_id
      : var.existing_layer_sp_object_id
    )
  }

  layer_principal_client_ids = {
    for layer in local.layer_names :
    layer => (
      var.layer_sp_mode == "create"
      ? azuread_application.layer[layer].client_id
      : var.existing_layer_sp_client_id
    )
  }
}

# Scope/role/principal tuple is unique per layer because scope changes by storage account.
resource "azurerm_role_assignment" "layer_storage_data_contributor" {
  for_each = local.layer_map

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.layer_principal_object_ids[each.key]
}

resource "azurerm_role_assignment" "connector_storage_data_contributor" {
  for_each = local.layer_map

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "deployer_keyvault_admin" {
  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.azure_sp_object_id
}

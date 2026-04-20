resource "azurerm_resource_group" "platform" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                             = local.storage_account_names[each.key]
  resource_group_name              = azurerm_resource_group.platform.name
  location                         = azurerm_resource_group.platform.location
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  account_kind                     = "StorageV2"
  is_hns_enabled                   = true
  min_tls_version                  = "TLS1_2"
  allow_nested_items_to_be_public  = false

  # Keep this enabled for reliable provider behavior during provisioning.
  # You can harden to false post-deployment if your operating model requires it.
  shared_access_key_enabled = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "layer" {
  for_each = local.layers

  name               = each.key
  storage_account_id = azurerm_storage_account.layer[each.key].id
}

resource "azurerm_databricks_workspace" "this" {
  name                        = local.databricks_workspace
  resource_group_name         = azurerm_resource_group.platform.name
  location                    = azurerm_resource_group.platform.location
  sku                         = "premium"
  managed_resource_group_name = "${azurerm_resource_group.platform.name}-databricks-managed"
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = "dbac-${var.workload}-${local.layers[each.key]}-${var.environment}-${local.region_abbr}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault" "this" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.platform.location
  resource_group_name        = azurerm_resource_group.platform.name
  tenant_id                  = var.azure_tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  rbac_authorization_enabled = true
}

resource "azuread_application" "layer" {
  for_each = local.create_layer_principals ? local.layers : {}

  display_name = "app-${var.workload}-${each.key}-${var.environment}"
}

resource "azuread_service_principal" "layer" {
  for_each = local.create_layer_principals ? local.layers : {}

  client_id = azuread_application.layer[each.key].client_id
}

locals {
  layer_principal_client_ids = local.create_layer_principals ? {
    for layer, _ in local.layers : layer => azuread_application.layer[layer].client_id
  } : {
    for layer, _ in local.layers : layer => var.existing_layer_sp_client_id
  }

  layer_principal_object_ids = local.create_layer_principals ? {
    for layer, _ in local.layers : layer => azuread_service_principal.layer[layer].object_id
  } : {
    for layer, _ in local.layers : layer => var.existing_layer_sp_object_id
  }
}

resource "azurerm_role_assignment" "layer_storage_contributor" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.layer_principal_object_ids[each.key]
}

resource "azurerm_role_assignment" "connector_storage_contributor" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "deployment_keyvault_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.azure_sp_object_id
}

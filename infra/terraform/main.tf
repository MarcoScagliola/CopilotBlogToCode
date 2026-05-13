resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  rbac_authorization_enabled = true

  tags = {
    workload    = var.workload
    environment = var.environment
    region      = var.azure_region
  }
}

resource "azurerm_databricks_workspace" "main" {
  name                          = local.databricks_workspace_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  managed_resource_group_name   = local.databricks_mrg_name
  sku                           = "premium"
  public_network_access_enabled = true

  custom_parameters {
    no_public_ip = true
  }

  tags = {
    workload    = var.workload
    environment = var.environment
    region      = var.azure_region
  }
}

resource "azurerm_storage_account" "layer" {
  for_each = local.storage_account_names

  name                      = each.value
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  account_tier              = "Standard"
  account_replication_type  = upper(var.storage_account_replication_type)
  account_kind              = "StorageV2"
  is_hns_enabled            = true
  shared_access_key_enabled = var.enable_shared_key

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
    region      = var.azure_region
  }
}

resource "azurerm_storage_container" "layer" {
  for_each = local.storage_account_names

  name                  = each.key
  storage_account_id    = azurerm_storage_account.layer[each.key].id
  container_access_type = "private"
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.access_connector_names

  name                = each.value
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  identity {
    type = "SystemAssigned"
  }

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
    region      = var.azure_region
  }
}

resource "azuread_application" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : toset([])

  display_name = "sp-${var.workload}-${var.environment}-${each.key}-${local.region_abbr}"
}

resource "azuread_service_principal" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : toset([])

  client_id = azuread_application.layer[each.key].client_id
}

locals {
  layer_principal_client_ids = var.layer_sp_mode == "create" ? {
    for layer in local.layers : layer => azuread_application.layer[layer].client_id
  } : {
    for layer in local.layers : layer => var.existing_layer_sp_client_id
  }

  layer_principal_object_ids = var.layer_sp_mode == "create" ? {
    for layer in local.layers : layer => azuread_service_principal.layer[layer].object_id
  } : {
    for layer in local.layers : layer => var.existing_layer_sp_object_id
  }
}

resource "azurerm_role_assignment" "kv_deployment_sp" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}

resource "azurerm_role_assignment" "kv_layer_sp" {
  for_each = local.layer_principal_object_ids

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "storage_access_connector" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_layer_sp" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.layer_principal_object_ids[each.key]
}

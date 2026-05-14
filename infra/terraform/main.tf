resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layer_names

  name                     = substr(lower("st${var.workload}${var.environment}${local.region_abbreviation}${substr(each.key, 0, 1)}"), 0, 24)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
  }
}

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 90
  enable_rbac_authorization  = true

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_databricks_workspace" "main" {
  name                = local.workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.databricks_workspace_sku

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layer_names

  name                = "acn-${var.workload}-${var.environment}-${each.key}-${local.region_abbreviation}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
  }
}

resource "azuread_application" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layer_names : toset([])

  display_name = "sp-${var.workload}-${var.environment}-${each.key}"
}

resource "azuread_service_principal" "layer" {
  for_each = azuread_application.layer

  client_id = each.value.client_id
}

resource "azurerm_role_assignment" "storage_layer_sp" {
  for_each = local.layer_names

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.layer_principal_object_ids[each.key]
}

resource "azurerm_role_assignment" "storage_access_connector" {
  for_each = local.layer_names

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "keyvault_layer_sp" {
  for_each = local.layer_names

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.layer_principal_object_ids[each.key]
}

resource "azurerm_role_assignment" "keyvault_deployment_sp" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}
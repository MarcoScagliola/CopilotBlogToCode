resource "azurerm_resource_group" "platform" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                            = local.layer_storage_account_names[each.key]
  resource_group_name             = azurerm_resource_group.platform.name
  location                        = azurerm_resource_group.platform.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  is_hns_enabled                  = true
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = var.shared_access_key_enabled
  default_to_oauth_authentication = true
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = "ac-${var.workload}-${each.key}-${var.environment}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "connector_storage_access" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azurerm_databricks_workspace" "main" {
  name                          = local.workspace_name
  resource_group_name           = azurerm_resource_group.platform.name
  location                      = azurerm_resource_group.platform.location
  sku                           = "premium"
  managed_resource_group_name   = "${local.resource_group_name}-managed"
  public_network_access_enabled = true

  custom_parameters {
    no_public_ip = true
  }
}

resource "azurerm_key_vault" "platform" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.platform.location
  resource_group_name        = azurerm_resource_group.platform.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
}

resource "azurerm_role_assignment" "deployer_key_vault_officer" {
  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}

resource "azuread_application" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : {}

  display_name = "${var.workload}-${var.environment}-${each.key}-layer"
}

resource "azuread_service_principal" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : {}

  client_id = azuread_application.layer[each.key].client_id
}

resource "azuread_service_principal_password" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : {}

  service_principal_id = azuread_service_principal.layer[each.key].id
  end_date             = timeadd(timestamp(), "8760h")
}

resource "azurerm_role_assignment" "layer_storage_access" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.layer_sp_mode == "create" ? azuread_service_principal.layer[each.key].object_id : var.existing_layer_sp_object_id
}

resource "azurerm_role_assignment" "layer_key_vault_reader" {
  for_each = var.layer_sp_mode == "create" ? local.layers : {}

  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.layer[each.key].object_id
}

resource "azurerm_role_assignment" "existing_layer_key_vault_reader" {
  count = var.layer_sp_mode == "existing" ? 1 : 0

  scope                = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.existing_layer_sp_object_id
}
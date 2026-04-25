resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_storage_account" "layer" {
  for_each = local.storage_account_names

  name                     = each.value
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Keep key-based auth enabled by default for maximum provider/runtime compatibility.
  shared_access_key_enabled = true

  min_tls_version            = "TLS1_2"
  https_traffic_only_enabled = true
}

resource "azurerm_key_vault" "main" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
}

resource "azurerm_databricks_workspace" "main" {
  name                = local.databricks_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  public_network_access_enabled = true

  custom_parameters {
    no_public_ip = true
  }
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layer_map

  name                = local.access_connector_names[each.key]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azuread_application" "layer" {
  for_each = local.create_layer_identities ? local.layer_map : {}

  display_name = "sp-${var.workload}-${var.environment}-${each.key}"
}

resource "azuread_service_principal" "layer" {
  for_each = azuread_application.layer

  client_id = each.value.client_id
}

resource "azurerm_role_assignment" "deployment_principal_key_vault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.deployment_sp_object_id
}

resource "azurerm_role_assignment" "layer_storage_blob_contributor" {
  for_each = local.layer_map

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.layer_principal_object_ids[each.key]
}

resource "azurerm_role_assignment" "access_connector_storage_blob_contributor" {
  for_each = local.layer_map

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azurerm_role_assignment" "layer_key_vault_secrets_user" {
  for_each = local.layer_map

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.layer_principal_object_ids[each.key]
}

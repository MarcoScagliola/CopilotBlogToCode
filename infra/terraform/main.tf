data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.azure_region
  tags     = local.tags
}

resource "azurerm_databricks_workspace" "this" {
  name                          = local.databricks_workspace_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = var.databricks_sku
  managed_resource_group_name   = local.managed_resource_group_name
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layer_configs

  name                            = local.storage_account_names[each.key]
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags                            = merge(local.tags, { layer = each.key })
}

resource "azurerm_storage_container" "layer" {
  for_each = local.layer_configs

  name                  = local.storage_container_name
  storage_account_id    = azurerm_storage_account.layer[each.key].id
  container_access_type = "private"
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layer_configs

  name                = local.layer_names[each.key].access_connector
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = merge(local.tags, { layer = each.key })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "layer_storage_contributor" {
  for_each = local.layer_configs

  scope                            = azurerm_storage_account.layer[each.key].id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "layer_upstream_reader" {
  for_each = local.upstream_layers

  scope                            = azurerm_storage_account.layer[each.value].id
  role_definition_name             = "Storage Blob Data Reader"
  principal_id                     = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_key_vault" "this" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  tenant_id                     = var.azure_tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  public_network_access_enabled = true
  soft_delete_retention_days    = 7
  tags                          = local.tags
}

resource "azuread_application" "layer" {
  for_each = local.layer_configs

  display_name = local.layer_names[each.key].application
}

resource "azuread_service_principal" "layer" {
  for_each = local.layer_configs

  client_id = azuread_application.layer[each.key].client_id
}

resource "azurerm_role_assignment" "key_vault_secret_user" {
  for_each = local.layer_configs

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.layer[each.key].object_id
}

resource "databricks_service_principal" "layer" {
  provider = databricks.workspace
  for_each = local.layer_configs

  application_id = azuread_application.layer[each.key].client_id
  display_name   = local.layer_names[each.key].application
  active         = true

  depends_on = [azurerm_databricks_workspace.this]
}

resource "databricks_storage_credential" "layer" {
  provider = databricks.workspace
  for_each = local.layer_configs

  name    = local.layer_names[each.key].storage_credential
  comment = "Storage credential for the ${each.key} medallion layer"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.layer[each.key].id
  }

  depends_on = [azurerm_role_assignment.layer_storage_contributor]
}

resource "databricks_external_location" "layer" {
  provider = databricks.workspace
  for_each = local.layer_configs

  name            = local.layer_names[each.key].external_location
  url             = format("abfss://%s@%s.dfs.core.windows.net/", azurerm_storage_container.layer[each.key].name, azurerm_storage_account.layer[each.key].name)
  credential_name = databricks_storage_credential.layer[each.key].name
  comment         = "External location root for the ${each.key} layer"

  depends_on = [databricks_storage_credential.layer]
}

resource "databricks_catalog" "layer" {
  provider = databricks.workspace
  for_each = local.layer_configs

  name         = local.layer_names[each.key].catalog
  comment      = "Managed tables catalog for the ${each.key} layer"
  storage_root = "${databricks_external_location.layer[each.key].url}managed"

  depends_on = [databricks_external_location.layer]
}

resource "databricks_schema" "layer" {
  provider = databricks.workspace
  for_each = local.layer_configs

  catalog_name = databricks_catalog.layer[each.key].name
  name         = local.layer_names[each.key].schema
  comment      = "Primary schema for the ${each.key} layer"
}

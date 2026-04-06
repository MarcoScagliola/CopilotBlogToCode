locals {
  layers = toset(["bronze", "silver", "gold"])

  upstream_layer = {
    silver = "bronze"
    gold   = "silver"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.azure_region
  tags     = merge(var.tags, { environment = var.environment })
}

resource "azurerm_virtual_network" "this" {
  count = var.enable_networking ? 1 : 0

  name                = var.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = merge(var.tags, { environment = var.environment })
}

resource "azurerm_subnet" "public" {
  count = var.enable_networking ? 1 : 0

  name                 = var.public_subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = var.public_subnet_address_prefixes
}

resource "azurerm_subnet" "private" {
  count = var.enable_networking ? 1 : 0

  name                 = var.private_subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = var.private_subnet_address_prefixes
}

resource "azurerm_network_security_group" "this" {
  count = var.enable_networking ? 1 : 0

  name                = var.nsg_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = merge(var.tags, { environment = var.environment })
}

resource "azurerm_subnet_network_security_group_association" "public" {
  count = var.enable_networking ? 1 : 0

  subnet_id                 = azurerm_subnet.public[0].id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count = var.enable_networking ? 1 : 0

  subnet_id                 = azurerm_subnet.private[0].id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                     = var.layer_storage_account_names[each.key]
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  tags                     = merge(var.tags, { layer = each.key, environment = var.environment })
}

resource "azurerm_storage_container" "layer" {
  for_each = local.layers

  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.layer[each.key].id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "layer" {
  for_each = local.layers

  name                = var.layer_managed_identity_names[each.key]
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = merge(var.tags, { layer = each.key, environment = var.environment })
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = var.layer_access_connector_names[each.key]
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = merge(var.tags, { layer = each.key, environment = var.environment })

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.layer[each.key].id]
  }
}

resource "azurerm_role_assignment" "layer_write" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.layer[each.key].principal_id
}

resource "azurerm_role_assignment" "layer_read_upstream" {
  for_each = local.upstream_layer

  scope                = azurerm_storage_account.layer[each.value].id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.layer[each.key].principal_id
}

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true
  purge_protection_enabled  = true

  tags = merge(var.tags, { environment = var.environment })
}

resource "azurerm_role_assignment" "keyvault_secret_user" {
  for_each = local.layers

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.layer[each.key].principal_id
}

resource "azuread_application" "layer" {
  for_each = local.layers

  display_name = var.layer_service_principal_display_names[each.key]
}

resource "azuread_service_principal" "layer" {
  for_each = local.layers

  client_id = azuread_application.layer[each.key].client_id
}

resource "databricks_service_principal" "layer" {
  provider = databricks.account
  for_each = local.layers

  application_id = azuread_application.layer[each.key].client_id
  display_name   = var.layer_service_principal_display_names[each.key]
  active         = true
}

resource "databricks_storage_credential" "layer" {
  for_each = local.layers

  name = var.layer_storage_credential_names[each.key]

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.layer[each.key].id
    managed_identity_id = azurerm_user_assigned_identity.layer[each.key].id
  }

  comment = "Storage credential for ${each.key} layer"
}

resource "databricks_external_location" "layer" {
  for_each = local.layers

  name            = var.layer_external_location_names[each.key]
  url             = "abfss://${var.storage_container_name}@${azurerm_storage_account.layer[each.key].name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.layer[each.key].name
  comment         = "External location for ${each.key} layer"
}

resource "databricks_catalog" "layer" {
  for_each = local.layers

  name    = var.layer_catalog_names[each.key]
  comment = "Catalog for ${each.key} medallion layer"
}

resource "databricks_schema" "layer" {
  for_each = local.layers

  catalog_name = databricks_catalog.layer[each.key].name
  name         = var.layer_schema_names[each.key]
  comment      = "Schema for ${each.key} medallion layer"
}

resource "databricks_grants" "catalog_layer_access" {
  for_each = local.layers

  catalog = databricks_catalog.layer[each.key].name

  grant {
    principal  = azuread_application.layer[each.key].client_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_TABLE", "SELECT"]
  }
}

resource "databricks_grants" "catalog_upstream_read" {
  for_each = local.upstream_layer

  catalog = databricks_catalog.layer[each.value].name

  grant {
    principal  = azuread_application.layer[each.key].client_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
}

data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.azure_region
}

resource "azurerm_databricks_workspace" "this" {
  name                = local.workspace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "premium"
}

resource "azurerm_storage_account" "layer" {
  for_each                 = var.layers
  name                     = local.storage_account_name[each.key]
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "layer" {
  for_each           = var.layers
  name               = "${each.key}-data"
  storage_account_id = azurerm_storage_account.layer[each.key].id
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each            = var.layers
  name                = local.access_connector_name[each.key]
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azuread_application" "layer" {
  for_each     = var.layers
  display_name = local.app_display_name[each.key]
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "layer" {
  for_each  = var.layers
  client_id = azuread_application.layer[each.key].client_id
}

resource "azuread_service_principal_password" "layer" {
  for_each             = var.layers
  service_principal_id = azuread_service_principal.layer[each.key].id
}

resource "azurerm_role_assignment" "layer_write" {
  for_each             = var.layers
  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.layer[each.key].object_id
}

resource "azurerm_role_assignment" "silver_read_bronze" {
  scope                = azurerm_storage_account.layer["bronze"].id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.layer["silver"].object_id
}

resource "azurerm_role_assignment" "gold_read_silver" {
  scope                = azurerm_storage_account.layer["silver"].id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.layer["gold"].object_id
}

resource "azurerm_key_vault" "this" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = data.azuread_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete"]
  }
}

resource "databricks_metastore_assignment" "this" {
  provider             = databricks.account
  workspace_id         = azurerm_databricks_workspace.this.workspace_id
  metastore_id         = var.databricks_metastore_id
  default_catalog_name = "main"
}

resource "databricks_secret_scope" "akv" {
  provider = databricks.workspace
  name     = "${var.workload}-${var.environment}-scope"
}

resource "databricks_storage_credential" "layer" {
  for_each = var.layers
  provider = databricks.workspace

  name = local.uc_storage_credential_name[each.key]

  azure_service_principal {
    directory_id = var.azure_tenant_id
    application_id = azuread_application.layer[each.key].client_id
    client_secret = azuread_service_principal_password.layer[each.key].value
  }
}

resource "databricks_external_location" "layer" {
  for_each = var.layers
  provider = databricks.workspace

  name            = local.uc_external_location_name[each.key]
  url             = "abfss://${each.key}-data@${azurerm_storage_account.layer[each.key].name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.layer[each.key].name
}

resource "databricks_catalog" "layer" {
  for_each = var.layers
  provider = databricks.workspace

  name = local.catalog_name[each.key]
}

resource "databricks_schema" "layer" {
  for_each = var.layers
  provider = databricks.workspace

  catalog_name = databricks_catalog.layer[each.key].name
  name         = local.schema_name[each.key]
}

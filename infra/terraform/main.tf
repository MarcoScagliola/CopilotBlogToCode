resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.azure_region
}

resource "azurerm_storage_account" "layer" {
  for_each = local.layer_configs

  name                      = each.value.storage_account_name
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  is_hns_enabled            = true
  shared_access_key_enabled = var.storage_shared_key_enabled

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
  }
}

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layer_configs

  name                = each.value.access_connector_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "ac_storage" {
  for_each = local.layer_configs

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

resource "azurerm_key_vault" "this" {
  name                      = local.kv_name
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  tenant_id                 = var.azure_tenant_id
  sku_name                  = "standard"
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "kv_secret_user" {
  for_each = toset(local.kv_secret_user_ids)

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azuread_application" "layer" {
  for_each = local.apps_to_create

  display_name = "sp-${local.prefix}-${each.key}"
}

resource "azuread_service_principal" "layer" {
  for_each = local.apps_to_create

  client_id = azuread_application.layer[each.key].client_id
}

resource "azuread_service_principal_password" "layer" {
  for_each = local.apps_to_create

  service_principal_id = azuread_service_principal.layer[each.key].id
}

resource "azurerm_databricks_workspace" "this" {
  name                = local.workspace
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "premium"
}

resource "databricks_metastore" "this" {
  name          = local.metastore
  region        = var.azure_region
  force_destroy = true
}

resource "databricks_metastore_assignment" "this" {
  workspace_id = azurerm_databricks_workspace.this.workspace_id
  metastore_id = databricks_metastore.this.id
}

resource "databricks_storage_credential" "layer" {
  for_each   = local.layer_configs
  depends_on = [databricks_metastore_assignment.this]

  name = "sc-${var.workload}-${var.environment}-${each.key}"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.layer[each.key].id
  }
}

resource "databricks_external_location" "layer" {
  for_each   = local.layer_configs
  depends_on = [databricks_storage_credential.layer]

  name            = "el-${var.workload}-${var.environment}-${each.key}"
  url             = "abfss://data@${azurerm_storage_account.layer[each.key].name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.layer[each.key].name
}

resource "databricks_catalog" "layer" {
  for_each   = local.layer_configs
  depends_on = [databricks_external_location.layer]

  name           = each.value.catalog_name
  metastore_id   = databricks_metastore.this.id
  storage_root   = databricks_external_location.layer[each.key].url
  isolation_mode = "ISOLATED"
  force_destroy  = true
}

resource "databricks_schema" "layer" {
  for_each = local.layer_configs

  catalog_name  = databricks_catalog.layer[each.key].name
  name          = each.value.schema_name
  force_destroy = true
}

resource "databricks_service_principal" "layer" {
  for_each = local.layer_configs

  application_id = local.layer_sp_client_ids[each.key]
  display_name   = "sp-${local.prefix}-${each.key}"
}

resource "databricks_grants" "catalog_layer" {
  for_each = local.layer_configs

  catalog = databricks_catalog.layer[each.key].name

  grant {
    principal  = databricks_service_principal.layer[each.key].application_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_TABLE", "MODIFY", "SELECT"]
  }
}

resource "databricks_secret_scope" "akv" {
  name = "akv-${var.workload}-${var.environment}"

  keyvault_metadata {
    resource_id = azurerm_key_vault.this.id
    dns_name    = azurerm_key_vault.this.vault_uri
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.azure_region
  tags     = local.common_tags
}

resource "azurerm_storage_account" "layers" {
  for_each = local.storage_account_names

  name                     = each.value
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
  tags                     = merge(local.common_tags, { layer = each.key })
}

resource "azurerm_storage_container" "layer_data" {
  for_each = azurerm_storage_account.layers

  name                  = "data"
  storage_account_name  = each.value.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "this" {
  name                            = local.key_vault_name
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = var.azure_tenant_id
  sku_name                        = "standard"
  purge_protection_enabled        = true
  soft_delete_retention_days      = 7
  enabled_for_template_deployment = true
  tags                            = local.common_tags
}

resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "Set",
    "List",
    "Delete",
    "Recover",
    "Purge"
  ]
}

resource "azurerm_key_vault_secret" "jdbc_host" {
  name         = "jdbc-host"
  value        = var.jdbc_host
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "jdbc_database" {
  name         = "jdbc-database"
  value        = var.jdbc_database
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "jdbc_user" {
  name         = "jdbc-user"
  value        = var.jdbc_user
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "jdbc_password" {
  name         = "jdbc-password"
  value        = var.jdbc_password
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.deployer]
}

resource "azuread_application" "layer_apps" {
  for_each     = local.application_names
  display_name = each.value
}

resource "azuread_service_principal" "layer_sps" {
  for_each  = azuread_application.layer_apps
  client_id = each.value.client_id
}

resource "azurerm_databricks_access_connector" "layers" {
  for_each = local.access_connector_names

  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = merge(local.common_tags, { layer = each.key })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "layer_sp_storage_blob_contributor" {
  for_each = azuread_service_principal.layer_sps

  scope                = azurerm_storage_account.layers[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.object_id
}

resource "azurerm_role_assignment" "access_connector_storage_blob_contributor" {
  for_each = azurerm_databricks_access_connector.layers

  scope                = azurerm_storage_account.layers[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.identity[0].principal_id
}

resource "azurerm_databricks_workspace" "this" {
  name                        = local.databricks_workspace
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = "mrg-${local.normalized_workload}-${local.normalized_env}-${local.region_abbreviation}"
  tags                        = local.common_tags
}

resource "databricks_metastore_assignment" "this" {
  workspace_id = azurerm_databricks_workspace.this.workspace_id
  metastore_id = var.databricks_metastore_id
}

resource "databricks_service_principal" "layer_sps" {
  for_each       = azuread_application.layer_apps
  application_id = each.value.client_id
  display_name   = local.application_names[each.key]
  active         = true

  depends_on = [azurerm_databricks_workspace.this]
}

resource "databricks_secret_scope" "key_vault_scope" {
  name = local.secret_scope_name

  keyvault_metadata {
    resource_id = azurerm_key_vault.this.id
    dns_name    = azurerm_key_vault.this.vault_uri
  }

  depends_on = [azurerm_databricks_workspace.this]
}

resource "databricks_storage_credential" "layers" {
  for_each = local.storage_credential_names

  name    = each.value
  comment = "Storage credential for ${each.key} layer"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.layers[each.key].id
  }

  depends_on = [
    databricks_metastore_assignment.this,
    azurerm_role_assignment.access_connector_storage_blob_contributor
  ]
}

resource "databricks_external_location" "layers" {
  for_each = local.external_location_names

  name            = each.value
  credential_name = databricks_storage_credential.layers[each.key].name
  url             = "abfss://${azurerm_storage_container.layer_data[each.key].name}@${azurerm_storage_account.layers[each.key].name}.dfs.core.windows.net/"
  comment         = "External location for ${each.key} medallion layer"

  depends_on = [databricks_storage_credential.layers]
}

resource "databricks_catalog" "layers" {
  for_each = local.catalog_names

  name         = each.value
  comment      = "${upper(each.key)} catalog for secure medallion architecture"
  storage_root = databricks_external_location.layers[each.key].url
  depends_on   = [databricks_external_location.layers]
}

resource "databricks_schema" "layers" {
  for_each = local.schema_names

  catalog_name = databricks_catalog.layers[each.key].name
  name         = each.value
  comment      = "Primary schema for ${each.key} layer"
}

resource "databricks_grants" "catalog_grants" {
  for_each = databricks_catalog.layers

  catalog = each.value.name

  grant {
    principal  = databricks_service_principal.layer_sps[each.key].application_id
    privileges = ["USE_CATALOG", "CREATE_SCHEMA"]
  }
}

resource "databricks_grants" "schema_grants" {
  for_each = databricks_schema.layers

  schema = "${each.value.catalog_name}.${each.value.name}"

  grant {
    principal  = databricks_service_principal.layer_sps[each.key].application_id
    privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  }
}

resource "databricks_grants" "external_location_grants" {
  for_each = databricks_external_location.layers

  external_location = each.value.name

  grant {
    principal  = databricks_service_principal.layer_sps[each.key].application_id
    privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
  }
}
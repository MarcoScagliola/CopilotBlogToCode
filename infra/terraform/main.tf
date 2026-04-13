# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.azure_region
}

# ---------------------------------------------------------------------------
# Storage Accounts – one per medallion layer (ADLS Gen2 with HNS)
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "layers" {
  for_each = local.layers

  name                     = local.storage_account_names[each.key]
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
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

# ---------------------------------------------------------------------------
# Storage Containers – one per layer
# ---------------------------------------------------------------------------

resource "azurerm_storage_container" "layer_data" {
  for_each = local.layers

  name                  = "${each.key}-data"
  storage_account_name  = azurerm_storage_account.layers[each.key].name
  container_access_type = "private"
}

# ---------------------------------------------------------------------------
# Databricks Access Connectors – system-assigned managed identity per layer
# ---------------------------------------------------------------------------

resource "azurerm_databricks_access_connector" "layers" {
  for_each = local.layers

  name                = local.access_connector_names[each.key]
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
  }
}

# ---------------------------------------------------------------------------
# Entra Applications – one per layer (for SP-based Unity Catalog isolation)
# ---------------------------------------------------------------------------

resource "azuread_application" "layer_apps" {
  for_each = local.layers

  display_name = local.entra_app_names[each.key]
}

# ---------------------------------------------------------------------------
# Service Principals – one per layer app
# ---------------------------------------------------------------------------

resource "azuread_service_principal" "layer_sps" {
  for_each = local.layers

  client_id = azuread_application.layer_apps[each.key].client_id

  depends_on = [azuread_application.layer_apps]
}

# ---------------------------------------------------------------------------
# Key Vault – stores JDBC credentials and SP secrets
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = var.azure_tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Deployment SP access policy
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

# Key Vault access policies for each layer SP
resource "azurerm_key_vault_access_policy" "layer_sps" {
  for_each = local.layers

  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.azure_tenant_id
  object_id    = azuread_service_principal.layer_sps[each.key].object_id

  secret_permissions = ["Get", "List"]

  depends_on = [azurerm_key_vault.this, azuread_service_principal.layer_sps]
}

# ---------------------------------------------------------------------------
# Key Vault Secrets – JDBC source credentials
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "jdbc_host" {
  name         = "jdbc-host"
  value        = var.jdbc_host
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault.this]
}

resource "azurerm_key_vault_secret" "jdbc_database" {
  name         = "jdbc-database"
  value        = var.jdbc_database
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault.this]
}

resource "azurerm_key_vault_secret" "jdbc_user" {
  name         = "jdbc-user"
  value        = var.jdbc_user
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault.this]
}

resource "azurerm_key_vault_secret" "jdbc_password" {
  name         = "jdbc-password"
  value        = var.jdbc_password
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault.this]
}

# ---------------------------------------------------------------------------
# RBAC: Storage Blob Data Contributor for each layer SP on its own account
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "sp_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layers[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.layer_sps[each.key].object_id
}

# ---------------------------------------------------------------------------
# RBAC: Storage Blob Data Contributor for each access connector on its account
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "access_connector_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layers[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layers[each.key].identity[0].principal_id
}

# ---------------------------------------------------------------------------
# Databricks Workspace – Premium SKU required for Unity Catalog
# ---------------------------------------------------------------------------

resource "azurerm_databricks_workspace" "this" {
  name                = local.databricks_workspace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "premium"

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Unity Catalog: Metastore Assignment
# ---------------------------------------------------------------------------

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.account
  metastore_id = var.databricks_metastore_id
  workspace_id = azurerm_databricks_workspace.this.workspace_id

  depends_on = [azurerm_databricks_workspace.this]
}

# ---------------------------------------------------------------------------
# Unity Catalog: Databricks Service Principals (mirrors Entra SPs)
# ---------------------------------------------------------------------------

resource "databricks_service_principal" "layer_sps" {
  for_each = local.layers

  provider       = databricks.workspace
  application_id = azuread_application.layer_apps[each.key].client_id
  display_name   = local.entra_app_names[each.key]

  depends_on = [databricks_metastore_assignment.this]
}

# ---------------------------------------------------------------------------
# Databricks Secret Scope – backed by Azure Key Vault
# ---------------------------------------------------------------------------

resource "databricks_secret_scope" "key_vault_scope" {
  provider = databricks.workspace
  name     = local.secret_scope_name

  keyvault_metadata {
    resource_id = azurerm_key_vault.this.id
    dns_name    = azurerm_key_vault.this.vault_uri
  }

  depends_on = [databricks_metastore_assignment.this, azurerm_key_vault.this]
}

# ---------------------------------------------------------------------------
# Unity Catalog: Storage Credentials (access connector managed identity)
# ---------------------------------------------------------------------------

resource "databricks_storage_credential" "layers" {
  for_each = local.layers

  provider = databricks.workspace
  name     = local.storage_credential_names[each.key]

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.layers[each.key].id
  }

  depends_on = [databricks_metastore_assignment.this, azurerm_role_assignment.access_connector_storage]
}

# ---------------------------------------------------------------------------
# Unity Catalog: External Locations (abfss:// per layer)
# ---------------------------------------------------------------------------

resource "databricks_external_location" "layers" {
  for_each = local.layers

  provider        = databricks.workspace
  name            = local.external_location_names[each.key]
  url             = "abfss://${each.key}-data@${azurerm_storage_account.layers[each.key].name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.layers[each.key].name

  depends_on = [databricks_storage_credential.layers]
}

# ---------------------------------------------------------------------------
# Unity Catalog: Catalogs
# ---------------------------------------------------------------------------

resource "databricks_catalog" "layers" {
  for_each = local.layers

  provider     = databricks.workspace
  name         = local.catalog_names[each.key]
  storage_root = databricks_external_location.layers[each.key].url

  depends_on = [databricks_external_location.layers]
}

# ---------------------------------------------------------------------------
# Unity Catalog: Schemas
# ---------------------------------------------------------------------------

resource "databricks_schema" "layers" {
  for_each = local.layers

  provider     = databricks.workspace
  catalog_name = databricks_catalog.layers[each.key].name
  name         = local.schema_names[each.key]

  depends_on = [databricks_catalog.layers]
}

# ---------------------------------------------------------------------------
# Unity Catalog: Grants – per-layer SP gets USE CATALOG, USE SCHEMA, CREATE TABLE
# ---------------------------------------------------------------------------

resource "databricks_grants" "catalog" {
  for_each = local.layers

  provider = databricks.workspace
  catalog  = databricks_catalog.layers[each.key].name

  grant {
    principal  = databricks_service_principal.layer_sps[each.key].application_id
    privileges = ["USE_CATALOG", "CREATE_SCHEMA"]
  }

  depends_on = [databricks_catalog.layers, databricks_service_principal.layer_sps]
}

resource "databricks_grants" "schema" {
  for_each = local.layers

  provider = databricks.workspace
  schema   = "${databricks_catalog.layers[each.key].name}.${databricks_schema.layers[each.key].name}"

  grant {
    principal  = databricks_service_principal.layer_sps[each.key].application_id
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_VOLUME"]
  }

  depends_on = [databricks_schema.layers, databricks_service_principal.layer_sps]
}

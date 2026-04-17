# ── Resource Group ────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.azure_region
}

# ── ADLS Gen2 Storage Accounts (one per layer) ───────────────────────────────
# storage_shared_key_enabled defaults to true for provider compatibility.
# The AzureRM provider polls blob storage with key-based auth during create/update.
# Disable this post-deployment once all access has switched to managed identity.

resource "azurerm_storage_account" "layer" {
  for_each = local.layer_configs

  name                     = each.value.storage_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # ADLS Gen2 hierarchical namespace
  shared_access_key_enabled = var.storage_shared_key_enabled

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
  }
}

# ── Databricks Access Connectors (one per layer) ─────────────────────────────
# Each connector exposes a system-assigned managed identity (SAMI) that Unity Catalog
# uses to access the corresponding ADLS Gen2 storage account.

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layer_configs

  name                = each.value.access_connector_name
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

# ── Storage Blob Contributor for Access Connectors ───────────────────────────
# Each Access Connector SAMI gets Storage Blob Data Contributor on its own layer's
# storage account only, enforcing least-privilege cross-layer isolation.

resource "azurerm_role_assignment" "ac_storage" {
  for_each = local.layer_configs

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

# ── Azure Key Vault ───────────────────────────────────────────────────────────
# rbac_authorization_enabled is the current property (enable_rbac_authorization is deprecated).

resource "azurerm_key_vault" "this" {
  name                     = local.kv_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  tenant_id                = var.azure_tenant_id
  sku_name                 = "standard"
  rbac_authorization_enabled = true # use RBAC, not legacy access policies

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

# Key Vault Secret User for the deployment SP and all layer SPs so they can read secrets at runtime.
resource "azurerm_role_assignment" "kv_secret_user" {
  for_each = toset([for id in local.kv_secret_user_object_ids : id])

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

# ── Entra ID Service Principals (per-layer, create mode only) ─────────────────
# Skipped when layer_service_principal_mode = "existing".
# Requires the deployment SP to have Directory.ReadWrite.All or Application.ReadWrite.All.

resource "azuread_application" "layer" {
  for_each = local.layer_apps_to_create

  display_name = "sp-${local.prefix}-${each.key}"
}

resource "azuread_service_principal" "layer" {
  for_each = local.layer_apps_to_create

  client_id = azuread_application.layer[each.key].client_id
}

resource "azuread_service_principal_password" "layer" {
  for_each = local.layer_apps_to_create

  service_principal_id = azuread_service_principal.layer[each.key].id
}

# ── Databricks Workspace ──────────────────────────────────────────────────────

resource "azurerm_databricks_workspace" "this" {
  name                = local.dbw_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "premium" # Required for Unity Catalog

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

# ── Unity Catalog: Metastore ──────────────────────────────────────────────────

resource "databricks_metastore" "this" {
  name          = local.uc_metastore
  region        = var.azure_region
  force_destroy = true
}

resource "databricks_metastore_assignment" "this" {
  metastore_id = databricks_metastore.this.id
  workspace_id = azurerm_databricks_workspace.this.workspace_id
}

# ── Unity Catalog: Storage Credentials (one per layer) ───────────────────────
# Links each Access Connector managed identity to Unity Catalog as a storage credential.

resource "databricks_storage_credential" "layer" {
  for_each     = local.layer_configs
  depends_on   = [databricks_metastore_assignment.this]

  name = "sc-${var.workload}-${var.environment}-${each.key}"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.layer[each.key].id
  }
}

# ── Unity Catalog: External Locations (one per layer) ────────────────────────

resource "databricks_external_location" "layer" {
  for_each   = local.layer_configs
  depends_on = [databricks_storage_credential.layer]

  name            = "el-${var.workload}-${var.environment}-${each.key}"
  url             = "abfss://data@${azurerm_storage_account.layer[each.key].name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.layer[each.key].name
}

# ── Unity Catalog: Catalogs (one per layer) ───────────────────────────────────
# Separate catalogs enforce cross-layer isolation: a bug in Silver code cannot
# accidentally read or write Gold because the Silver SP has no catalog-level grant on Gold.

resource "databricks_catalog" "layer" {
  for_each   = local.layer_configs
  depends_on = [databricks_external_location.layer]

  name            = each.value.catalog_name
  storage_root    = databricks_external_location.layer[each.key].url
  metastore_id    = databricks_metastore.this.id
  isolation_mode  = "ISOLATED"
  force_destroy   = true
}

# ── Unity Catalog: Schemas (one per layer) ────────────────────────────────────

resource "databricks_schema" "layer" {
  for_each = local.layer_configs

  catalog_name = databricks_catalog.layer[each.key].name
  name         = each.value.schema_name
  force_destroy = true
}

# ── Databricks Service Principals (per-layer) ────────────────────────────────
# Register each Entra SP in the Databricks workspace so they can be used as job runners.

resource "databricks_service_principal" "layer" {
  for_each = local.layer_configs

  application_id = local.layer_application_ids[each.key]
  display_name   = "sp-${local.prefix}-${each.key}"
}

# ── Unity Catalog Grants: per-layer SPs ──────────────────────────────────────
# Each SP can only USE / CREATE TABLE in its own catalog; no cross-layer grants.

resource "databricks_grants" "catalog_layer" {
  for_each = local.layer_configs

  catalog = databricks_catalog.layer[each.key].name

  grant {
    principal  = databricks_service_principal.layer[each.key].application_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_TABLE", "MODIFY", "SELECT"]
  }
}

# ── AKV-backed Secret Scope ───────────────────────────────────────────────────
# One scope per environment; notebooks read secrets at runtime via dbutils.secrets.get().

resource "databricks_secret_scope" "akv" {
  name = "akv-${var.workload}-${var.environment}"

  keyvault_metadata {
    resource_id = azurerm_key_vault.this.id
    dns_name    = azurerm_key_vault.this.vault_uri
  }
}

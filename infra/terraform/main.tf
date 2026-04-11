##############################################################################
# DATA SOURCES
##############################################################################

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

##############################################################################
# LOCALS
##############################################################################

locals {
  # CAF-style names
  rg_name  = "rg-${var.project_prefix}-${var.environment}-${var.azure_region}"
  kv_name  = "kv-${var.project_prefix}-${var.environment}"
  dbw_name = "dbw-${var.project_prefix}-${var.environment}"

  # Abbreviated layer names for storage account naming (max 24 chars, no hyphens)
  layer_abbrev = {
    bronze = "brz"
    silver = "slv"
    gold   = "gld"
  }

  # Storage account names: 3-24 lowercase alphanumeric, globally unique
  sa_names = {
    for layer, abbrev in local.layer_abbrev :
    layer => substr(lower(replace("st${var.project_prefix}${abbrev}${var.environment}", "-", "")), 0, 24)
  }

  # Unity Catalog schema per layer
  catalog_schemas = {
    bronze = "raw"
    silver = "clean"
    gold   = "serving"
  }
}

##############################################################################
# RESOURCE GROUP
##############################################################################

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region
  tags     = var.tags
}

##############################################################################
# STORAGE ACCOUNTS (ADLS Gen2, one per Medallion layer)
##############################################################################

resource "azurerm_storage_account" "layer" {
  for_each = local.layer_abbrev

  name                     = local.sa_names[each.key]
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # ADLS Gen2

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false # Entra ID authentication only

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "layer" {
  for_each = azurerm_storage_account.layer

  name               = each.key # bronze / silver / gold
  storage_account_id = each.value.id
}

##############################################################################
# DATABRICKS ACCESS CONNECTORS (system-assigned managed identity, one per layer)
##############################################################################

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layer_abbrev

  name                = "dbac-${var.project_prefix}-${each.key}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Grant each connector's SAMI Storage Blob Data Contributor on its own layer only
resource "azurerm_role_assignment" "connector_storage" {
  for_each = local.layer_abbrev

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

##############################################################################
# ENTRA ID SERVICE PRINCIPALS (one per layer — Lakeflow job run-as identity)
##############################################################################

resource "azuread_application" "layer" {
  for_each = local.layer_abbrev

  display_name = "sp-${var.project_prefix}-${each.key}-${var.environment}"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "layer" {
  for_each = azuread_application.layer

  client_id = each.value.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "layer" {
  for_each = azuread_application.layer

  application_id = each.value.id
  display_name   = "terraform-managed"
  # TODO: shorten and configure AKV rotation policy for production
  end_date = "2027-01-01T00:00:00Z"
}

##############################################################################
# KEY VAULT (RBAC-enabled; holds SP credentials and source secrets)
##############################################################################

resource "azurerm_key_vault" "main" {
  name                        = local.kv_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku_name                    = "standard"
  tenant_id                   = var.azure_tenant_id
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90
  enable_rbac_authorization   = true

  tags = var.tags
}

# Deployer identity gets Secrets Officer to write secrets during terraform apply
resource "azurerm_role_assignment" "kv_deployer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Each layer SP gets Secrets User so dbutils.secrets.get() works at runtime
resource "azurerm_role_assignment" "kv_sp_reader" {
  for_each = azuread_service_principal.layer

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.object_id
}

# Store each SP's client_id in AKV
resource "azurerm_key_vault_secret" "sp_client_id" {
  for_each = azuread_application.layer

  name         = "${each.key}-sp-client-id"
  value        = each.value.client_id
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_deployer]
}

# Store each SP's client_secret in AKV
resource "azurerm_key_vault_secret" "sp_client_secret" {
  for_each = azuread_application_password.layer

  name         = "${each.key}-sp-client-secret"
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_deployer]
}

# Store tenant ID for notebooks that need it at runtime
resource "azurerm_key_vault_secret" "tenant_id" {
  name         = "azure-tenant-id"
  value        = var.azure_tenant_id
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_deployer]
}

# TODO: add azurerm_monitor_diagnostic_setting for AKV audit logs once a
#       Log Analytics workspace is provisioned (see TODO.md).

##############################################################################
# DATABRICKS WORKSPACE (Premium SKU required for Unity Catalog)
##############################################################################

resource "azurerm_databricks_workspace" "main" {
  name                        = local.dbw_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = "premium"
  managed_resource_group_name = "rg-${var.project_prefix}-dbw-managed-${var.environment}"

  tags = var.tags
}

##############################################################################
# UNITY CATALOG — Metastore assignment
##############################################################################

resource "databricks_metastore_assignment" "main" {
  provider = databricks.account

  metastore_id = var.databricks_metastore_id
  workspace_id = tonumber(azurerm_databricks_workspace.main.workspace_id)
}

##############################################################################
# UNITY CATALOG — Register Entra SPs in Databricks workspace
##############################################################################

resource "databricks_service_principal" "layer" {
  for_each = local.layer_abbrev

  provider       = databricks.workspace
  application_id = azuread_application.layer[each.key].client_id
  display_name   = "sp-${var.project_prefix}-${each.key}-${var.environment}"

  allow_cluster_create = false

  depends_on = [databricks_metastore_assignment.main]
}

##############################################################################
# UNITY CATALOG — AKV-backed Secret Scope
##############################################################################

resource "databricks_secret_scope" "main" {
  provider = databricks.workspace
  name     = var.secret_scope_name

  keyvault_metadata {
    resource_id = azurerm_key_vault.main.id
    dns_name    = azurerm_key_vault.main.vault_uri
  }

  depends_on = [
    azurerm_role_assignment.kv_deployer,
    databricks_metastore_assignment.main,
  ]
}

##############################################################################
# UNITY CATALOG — Storage Credentials (Access Connector SAMIs)
##############################################################################

resource "databricks_storage_credential" "layer" {
  for_each = local.layer_abbrev

  provider = databricks.workspace
  name     = "stc-${var.project_prefix}-${each.key}-${var.environment}"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.layer[each.key].id
  }

  depends_on = [databricks_metastore_assignment.main]
}

##############################################################################
# UNITY CATALOG — External Locations (one per layer container)
##############################################################################

resource "databricks_external_location" "layer" {
  for_each = local.layer_abbrev

  provider        = databricks.workspace
  name            = "ext-loc-${var.project_prefix}-${each.key}-${var.environment}"
  url             = "abfss://${each.key}@${azurerm_storage_account.layer[each.key].name}.dfs.core.windows.net"
  credential_name = databricks_storage_credential.layer[each.key].name

  depends_on = [
    databricks_storage_credential.layer,
    azurerm_storage_data_lake_gen2_filesystem.layer,
  ]
}

##############################################################################
# UNITY CATALOG — Catalogs (one per layer, managed storage root)
##############################################################################

resource "databricks_catalog" "layer" {
  for_each = local.layer_abbrev

  provider     = databricks.workspace
  name         = "${each.key}_catalog"
  storage_root = databricks_external_location.layer[each.key].url

  depends_on = [databricks_external_location.layer]
}

##############################################################################
# UNITY CATALOG — Schemas
##############################################################################

resource "databricks_schema" "layer" {
  for_each = local.catalog_schemas

  provider     = databricks.workspace
  catalog_name = databricks_catalog.layer[each.key].name
  name         = each.value

  depends_on = [databricks_catalog.layer]
}

##############################################################################
# UNITY CATALOG — Grants (catalog level, least-privilege per blog pattern)
#
# Bronze SP  → writes to bronze only
# Silver SP  → reads bronze, writes silver
# Gold SP    → reads silver,  writes gold
#
# databricks_grants is authoritative per securable; all grants for a
# given catalog must be in a single resource block.
##############################################################################

resource "databricks_grants" "bronze_catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.layer["bronze"].name

  # Owner layer: full read/write
  grant {
    principal  = databricks_service_principal.layer["bronze"].application_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_TABLE", "SELECT", "MODIFY"]
  }

  # Downstream layer: read-only
  grant {
    principal  = databricks_service_principal.layer["silver"].application_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }

  depends_on = [databricks_schema.layer, databricks_service_principal.layer]
}

resource "databricks_grants" "silver_catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.layer["silver"].name

  grant {
    principal  = databricks_service_principal.layer["silver"].application_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_TABLE", "SELECT", "MODIFY"]
  }

  grant {
    principal  = databricks_service_principal.layer["gold"].application_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }

  depends_on = [databricks_schema.layer, databricks_service_principal.layer]
}

resource "databricks_grants" "gold_catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.layer["gold"].name

  grant {
    principal  = databricks_service_principal.layer["gold"].application_id
    privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_TABLE", "SELECT", "MODIFY"]
  }

  depends_on = [databricks_schema.layer, databricks_service_principal.layer]
}

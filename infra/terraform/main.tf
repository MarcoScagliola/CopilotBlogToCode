# ===========================================================================
# Resource group
# ===========================================================================

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
  tags     = local.common_tags
}

# ===========================================================================
# Per-layer storage accounts (ADLS Gen2)
# Three accounts — one per Medallion layer (Bronze, Silver, Gold).
# Each account is isolated so that layer service principals can be granted
# only their own storage, enforcing least-privilege access across layers.
# ===========================================================================

resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                     = local.storage_accounts[each.key]
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable hierarchical namespace (ADLS Gen2)
  is_hns_enabled = true

  # Allow shared access keys by default for provider compatibility.
  # Post-deployment hardening: disable shared access keys once managed identities
  # are verified working (the azurerm provider may still use shared keys during
  # certain operations).
  shared_access_key_enabled = true

  tags = merge(local.common_tags, { layer = each.key })
}

# ===========================================================================
# Per-layer Databricks Access Connectors
# Each connector carries a system-assigned managed identity (SAMI) that is
# used as a Unity Catalog storage credential for its layer's External Location.
# ===========================================================================

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = local.access_connectors[each.key]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.common_tags, { layer = each.key })
}

# ===========================================================================
# Storage Blob Data Contributor role — Access Connector → Storage Account
# Grants each Access Connector SAMI write access to its own layer's storage.
# This is the credential that backs Unity Catalog External Locations.
# Each (scope, role, principal) triple is unique across iterations.
# ===========================================================================

resource "azurerm_role_assignment" "connector_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

# ===========================================================================
# Entra ID app registrations and service principals — one per layer
# Only created when layer_sp_mode = "create".
# In restricted tenants where the deployment principal cannot create app
# registrations, set layer_sp_mode = "existing" and supply pre-created
# identifiers. No Microsoft Graph reads are performed in "existing" mode.
# ===========================================================================

resource "azuread_application" "layer" {
  # for_each keys are statically known (local.layers is a static set).
  for_each = local.create_layer_sps ? local.layers : toset([])

  display_name = local.layer_sp_app_names[each.key]
}

resource "azuread_service_principal" "layer" {
  for_each = local.create_layer_sps ? local.layers : toset([])

  # client_id is the application (client) ID of the app registration.
  client_id = azuread_application.layer[each.key].client_id
}

# ===========================================================================
# Storage Blob Data Contributor — layer service principal → storage account
# Grants each layer SP access to its own storage account only.
# Cross-layer access is blocked by design: a Bronze SP has no role on Silver
# or Gold storage, preventing accidental or malicious cross-contamination.
# Each (scope, role, principal) triple is unique across iterations.
# ===========================================================================

resource "azurerm_role_assignment" "layer_sp_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.resolved_layer_object_ids[each.key]

  # Depend on SP creation when in create mode to avoid race condition between
  # app registration and role assignment.
  depends_on = [azuread_service_principal.layer]
}

# ===========================================================================
# Azure Key Vault
# One vault per environment. Stores API keys, DB passwords, webhooks, and any
# other secrets the Lakeflow jobs need at runtime. Layer service principals are
# granted read access so they can fetch secrets via AKV-backed secret scopes
# in Databricks.
# ===========================================================================

resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # Soft-delete is enabled by default in Azure; purge protection may be
  # enabled post-deployment as a hardening step.
  soft_delete_retention_days = 7

  tags = local.common_tags
}

# Key Vault access policy — deployment principal (for secret management)
resource "azurerm_key_vault_access_policy" "deployment_sp" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.sp_object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

# Key Vault access policy — per-layer service principals (read-only at runtime)
resource "azurerm_key_vault_access_policy" "layer_sp" {
  for_each = local.layers

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = local.resolved_layer_object_ids[each.key]

  secret_permissions = ["Get", "List"]

  depends_on = [azuread_service_principal.layer]
}

# ===========================================================================
# Azure Databricks workspace
# Premium tier required for Unity Catalog. Secure Cluster Connectivity (SCC /
# No Public IP) is enabled as stated in the architecture.
# ===========================================================================

resource "azurerm_databricks_workspace" "main" {
  name                = local.workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "premium"

  # Secure Cluster Connectivity — eliminates public IPs on cluster nodes.
  # Stated requirement from the source article.
  custom_parameters {
    no_public_ip = true
  }

  tags = local.common_tags
}

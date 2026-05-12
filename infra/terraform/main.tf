# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# ADLS Gen2 Storage Accounts — one per layer
# HNS (Hierarchical Namespace) must be true for Unity Catalog managed tables.
# shared_access_key_enabled defaults to true because the AzureRM provider still
# uses key-based auth for some control-plane polling operations. Disable it
# post-deployment once all access paths are confirmed identity-based.
# See "Architectural decisions deferred" in TODO.md.
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "layer" {
  # Keys are static strings from local.layers — plan-time knowable.
  for_each = local.layers

  name                     = local.storage_names[each.key]
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Required for Unity Catalog managed tables.
  is_hns_enabled = true

  # Provider compatibility: keep enabled during initial provisioning.
  # See terraform skill — Provider Behavior Mismatches.
  shared_access_key_enabled = true

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Databricks Access Connectors — one per layer (System-Assigned Managed Identity)
# Each SAMI is the identity Unity Catalog uses to access that layer's storage.
# ---------------------------------------------------------------------------

resource "azurerm_databricks_access_connector" "layer" {
  # Same static layer keys — for_each is plan-time safe.
  for_each = local.layers

  name                = local.access_connector_names[each.key]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# RBAC: Access Connector SAMI → Storage (Storage Blob Data Contributor)
# Separate for_each per role-assignment because each iteration produces a
# unique (scope, role, principal) tuple — scope and principal both vary by layer.
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "connector_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

# ---------------------------------------------------------------------------
# Entra ID Layer Service Principals (conditional — only when layer_sp_mode = "create")
# Creates one app registration + service principal per layer.
# Requires Application.ReadWrite.All in the target Entra ID tenant.
# Set layer_sp_mode = "existing" in tenants where this is restricted.
# ---------------------------------------------------------------------------

resource "azuread_application" "layer" {
  # for_each over an empty set when create_layer_sps = false → zero resources created.
  for_each = local.create_layer_sps ? local.layers : toset([])

  display_name = local.sp_display_names[each.key]
}

resource "azuread_service_principal" "layer" {
  # Mirrors azuread_application.layer exactly so keys are statically known.
  for_each = local.create_layer_sps ? local.layers : toset([])

  client_id = azuread_application.layer[each.key].client_id

  depends_on = [azuread_application.layer]
}

# ---------------------------------------------------------------------------
# RBAC: Layer SP → Storage (Storage Blob Data Contributor)
# resolved_layer_object_ids handles both create and existing mode via ternary in locals.
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "layer_sp_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  # Apply-time value looked up by static key — for_each plan-time safety preserved.
  principal_id = local.resolved_layer_object_ids[each.key]

  depends_on = [
    azuread_service_principal.layer,
    azurerm_storage_account.layer,
  ]
}

# ---------------------------------------------------------------------------
# Azure Key Vault
# One vault per environment as recommended by the article.
# Soft-delete is enabled by default in all Azure subscriptions (cannot disable).
# purge_protection_enabled = false allows destroy without a 7-90 day wait.
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = local.kv_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  tags = local.common_tags
}

# Access policy for the deployment service principal (secret management during deploy).
resource "azurerm_key_vault_access_policy" "deployment_sp" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.sp_object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
}

# Access policy for layer service principals (runtime secret reads from notebooks/jobs).
# One access policy per layer; principal_id varies so no identity collision.
resource "azurerm_key_vault_access_policy" "layer_sp" {
  for_each = local.layers

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = local.resolved_layer_object_ids[each.key]

  secret_permissions = ["Get", "List"]

  depends_on = [
    azuread_service_principal.layer,
    azurerm_key_vault_access_policy.deployment_sp,
  ]
}

# ---------------------------------------------------------------------------
# Databricks Workspace — Premium tier, Secure Cluster Connectivity (No Public IP)
# ---------------------------------------------------------------------------

resource "azurerm_databricks_workspace" "main" {
  name                = local.workspace_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  # Secure Cluster Connectivity — explicitly required by the article.
  custom_parameters {
    no_public_ip = true
  }

  tags = local.common_tags
}

# ── Data sources ──────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# ── Resource group ─────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_region
  tags     = local.common_tags
}

# ── Per-layer ADLS Gen2 storage accounts ──────────────────────────────────────
# Hierarchical Namespace (is_hns_enabled) is required for ADLS Gen2.
# shared_access_key_enabled=true is required during provisioning because the AzureRM
# provider polls storage state via key auth even after creation. Disable after initial
# deploy — see TODO.md "shared_access_key_enabled = true on storage accounts".

resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                     = local.storage_name[each.key]
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  # Provider compatibility: AzureRM still polls storage via account keys during apply.
  # Post-deployment hardening: set to false once the deployment is stable.
  shared_access_key_enabled = true

  tags = merge(local.common_tags, { layer = each.key })
}

# ── Per-layer Databricks Access Connectors (SAMI) ─────────────────────────────
# Each access connector gets a system-assigned managed identity (SAMI) that is
# registered with Unity Catalog to grant least-privilege access to the layer's storage.

resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = local.access_connector_name[each.key]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.common_tags, { layer = each.key })
}

# ── Access connector → storage RBAC (Storage Blob Data Contributor) ───────────
# Each SAMI needs Storage Blob Data Contributor on its own layer's storage account.
# The role-definition iteration varies both scope and principal → no identity collision.

resource "azurerm_role_assignment" "connector_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

# ── Conditional Entra ID app registrations (layer_sp_mode=create only) ───────
# When layer_sp_mode=existing, this resource is not created; the existing principal
# identifiers from variable inputs are used directly.

resource "azuread_application" "layer" {
  for_each = local.create_layer_sps ? local.layers : toset([])

  display_name = local.sp_display_name[each.key]
}

# ── Conditional Entra ID service principals (layer_sp_mode=create only) ──────

resource "azuread_service_principal" "layer" {
  for_each = local.create_layer_sps ? local.layers : toset([])

  client_id = azuread_application.layer[each.key].client_id
}

# ── Layer SP → storage RBAC (Storage Blob Data Contributor) ──────────────────
# Each layer SP needs Storage Blob Data Contributor on its layer's storage account.
# In existing mode, the principal_id comes from var.existing_layer_sp_object_id
# (no Graph reads — restricted-tenant safe).

resource "azurerm_role_assignment" "layer_sp_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.resolved_layer_object_ids[each.key]
}

# ── Key Vault ──────────────────────────────────────────────────────────────────
# purge_protection_enabled=true is mandatory (one-way flag; omitting or setting false
# causes every subsequent modify to fail). See terraform skill — Key Vault Purge Protection.

resource "azurerm_key_vault" "main" {
  name                = local.kv_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Soft-delete retention window (minimum 7 days; default 90).
  soft_delete_retention_days = 7

  # One-way flag: once enabled, cannot be disabled. Always set explicitly.
  purge_protection_enabled = true

  tags = local.common_tags
}

# ── Key Vault access policy — deployment service principal ────────────────────
# Grants the deployment SP enough permissions to set secrets post-deploy.

resource "azurerm_key_vault_access_policy" "deployment_sp" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.sp_object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
  ]
}

# ── Key Vault access policy — layer service principals ────────────────────────
# Each layer SP gets Get+List so it can read runtime secrets at job execution time.

resource "azurerm_key_vault_access_policy" "layer_sp" {
  for_each = local.layers

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.resolved_layer_object_ids[each.key]

  secret_permissions = [
    "Get",
    "List",
  ]
}

# ── Azure Databricks Workspace (Premium, SCC/No Public IP) ────────────────────

resource "azurerm_databricks_workspace" "main" {
  name                = local.workspace_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  # Secure Cluster Connectivity (No Public IP) — stated explicitly in the article.
  custom_parameters {
    no_public_ip = true
  }

  tags = local.common_tags
}

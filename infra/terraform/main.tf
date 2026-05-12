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
  # Post-deployment hardening: disable shared access keys once managed
  # identities are verified working.
  shared_access_key_enabled = true

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = merge(local.common_tags, { layer = each.key })
}

# ===========================================================================
# Per-layer Databricks Access Connectors
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
# Storage Blob Data Contributor — Access Connector SAMI → layer storage
# Backs Unity Catalog External Locations. Each (scope, role, principal) is unique.
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
# ===========================================================================

resource "azuread_application" "layer" {
  # for_each keys are statically known (local.layers is a static set).
  for_each = local.create_layer_sps ? local.layers : toset([])

  display_name = local.layer_sp_app_names[each.key]
}

resource "azuread_service_principal" "layer" {
  for_each = local.create_layer_sps ? local.layers : toset([])

  client_id = azuread_application.layer[each.key].client_id
}

# ===========================================================================
# Storage Blob Data Contributor — layer SP → layer storage
# Each (scope, role, principal) triple is unique across iterations.
# ===========================================================================

resource "azurerm_role_assignment" "layer_sp_to_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.resolved_layer_object_ids[each.key]

  depends_on = [azuread_service_principal.layer]
}

# ===========================================================================
# Azure Key Vault
# ===========================================================================

resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = local.common_tags
}

# Key Vault access policy — deployment principal
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
# Azure Databricks workspace (Premium, SCC / No Public IP)
# ===========================================================================

resource "azurerm_databricks_workspace" "main" {
  name                = local.workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "premium"

  # Secure Cluster Connectivity — eliminates public IPs on cluster nodes.
  custom_parameters {
    no_public_ip = true
  }

  tags = local.common_tags
}

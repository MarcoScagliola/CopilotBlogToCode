# ── Resource Group ─────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
}

# ── Per-layer Storage Accounts & Containers ────────────────────────────────────

resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                     = local.storage_account_names[each.key]
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # ADLS Gen2
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
  }
}

resource "azurerm_storage_container" "layer" {
  for_each = local.layers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.layer[each.key].id
  container_access_type = "private"
}

# ── Databricks Access Connectors ───────────────────────────────────────────────

resource "azurerm_databricks_access_connector" "layer" {
  for_each = var.enable_access_connectors ? local.layers : {}

  name                = local.access_connector_names[each.key]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    workload    = var.workload
    environment = var.environment
    layer       = each.key
  }
}

# ── RBAC: Access Connector SAMI → Storage ─────────────────────────────────────

resource "azurerm_role_assignment" "ac_storage" {
  for_each = var.enable_access_connectors ? local.layers : {}

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

# ── RBAC: Layer SP → Storage ───────────────────────────────────────────────────

locals {
  layer_sp_object_id = var.layer_sp_mode == "existing" ? var.existing_layer_sp_object_id : (
    var.layer_sp_mode == "create" ? azuread_service_principal.layer["bronze"].object_id : ""
  )
}

resource "azurerm_role_assignment" "sp_storage" {
  for_each = local.layers

  scope                = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.layer_sp_object_id
}

# ── Databricks Workspace ───────────────────────────────────────────────────────

resource "azurerm_databricks_workspace" "main" {
  name                = local.databricks_workspace_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

# ── Key Vault ──────────────────────────────────────────────────────────────────

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization   = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_role_assignment" "deployment_sp_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployment_sp_object_id
}

resource "azurerm_role_assignment" "layer_sp_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.layer_sp_object_id
}

# ── Entra ID SPs (create mode only) ────────────────────────────────────────────

resource "azuread_application" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : {}

  display_name = "sp-${each.key}-${var.workload}-${var.environment}"
}

resource "azuread_service_principal" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : {}

  client_id = azuread_application.layer[each.key].client_id
}

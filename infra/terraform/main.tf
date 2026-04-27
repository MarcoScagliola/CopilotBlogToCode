resource "azurerm_resource_group" "platform" {
  name       = local.resource_group_name
  location   = var.azure_region
  tags       = local.common_tags
}

# Per-layer storage accounts (Bronze, Silver, Gold)
resource "azurerm_storage_account" "layer" {
  for_each = local.layers

  name                            = local.layer_names[each.key].storage_account
  resource_group_name             = azurerm_resource_group.platform.name
  location                        = azurerm_resource_group.platform.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = var.shared_access_key_enabled
  default_to_oauth_authentication = true

  tags = merge(
    local.common_tags,
    { layer = each.key }
  )

  depends_on = [azurerm_resource_group.platform]
}

# Enable ADLS Gen2 on each storage account
resource "azurerm_storage_data_lake_gen2_filesystem" "layer" {
  for_each = azurerm_storage_account.layer

  name               = "${each.key}-data"
  storage_account_id = each.value.id
}

# Per-layer Access Connectors for Databricks
resource "azurerm_databricks_access_connector" "layer" {
  for_each = local.layers

  name                = "dbx-ac-${each.key}-${var.environment}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    local.common_tags,
    { layer = each.key }
  )

  depends_on = [azurerm_resource_group.platform]
}

# Assign Storage Blob Data Contributor to each access connector's managed identity
resource "azurerm_role_assignment" "access_connector_to_storage" {
  for_each = local.layers

  scope              = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azurerm_databricks_access_connector.layer[each.key].identity[0].principal_id
}

# Azure Databricks Workspace
resource "azurerm_databricks_workspace" "main" {
  name                = "dbx-${var.workload}-${var.environment}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  sku                 = "premium"

  # Secure cluster connectivity (no public IP)
  network_security_group_rules_required = "NoAzureDatabricksRules"
  public_network_access_enabled         = true
  managed_resource_group_name           = "${local.resource_group_name}-managed"

  tags = local.common_tags

  depends_on = [azurerm_resource_group.platform]
}

# Azure Key Vault
resource "azurerm_key_vault" "platform" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.platform.location
  resource_group_name         = azurerm_resource_group.platform.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  rbac_authorization_enabled  = true
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false

  tags = local.common_tags

  depends_on = [azurerm_resource_group.platform]
}

# Key Vault secret permissions for deployment principal
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope              = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id       = var.sp_object_id
}

# Key Vault secret permissions for layer principal (when using existing)
resource "azurerm_role_assignment" "kv_secrets_user_layer" {
  count              = var.layer_sp_mode == "existing" ? 1 : 0
  scope              = azurerm_key_vault.platform.id
  role_definition_name = "Key Vault Secrets User"
  principal_id       = var.existing_layer_sp_object_id
}

# Per-layer service principals (when layer_sp_mode = create)
resource "azuread_application" "layer" {
  for_each = var.layer_sp_mode == "create" ? local.layers : {}

  display_name = "${var.workload}-${each.key}-layer"
}

resource "azuread_service_principal" "layer" {
  for_each = azuread_application.layer

  client_id = each.value.client_id
}

resource "azuread_service_principal_password" "layer" {
  for_each = azuread_service_principal.layer

  service_principal_id = each.value.id
  end_date             = timeadd(timestamp(), "8736h") # 1 year
}

# Assign Storage Blob Data Contributor to layer principals
resource "azurerm_role_assignment" "layer_principal_to_storage" {
  for_each = var.layer_sp_mode == "create" ? {
    for layer in keys(azurerm_storage_account.layer) :
    layer => {
      storage_account_id = azurerm_storage_account.layer[layer].id
      principal_id       = azuread_service_principal.layer[layer].id
    }
  } : {}

  scope              = each.value.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = each.value.principal_id
}

# Assign Storage Blob Data Contributor to layer principal when using existing
resource "azurerm_role_assignment" "existing_layer_principal_to_storage" {
  for_each = var.layer_sp_mode == "existing" ? local.layers : {}

  scope              = azurerm_storage_account.layer[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = var.existing_layer_sp_object_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region

  tags = {
    workload    = var.workload
    environment = var.environment
    pattern     = "secure-medallion"
  }
}

resource "azurerm_key_vault" "main" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = true

  tags = {
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_storage_account" "bronze" {
  name                            = local.bronze_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false

  tags = {
    layer       = "bronze"
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_storage_account" "silver" {
  name                            = local.silver_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false

  tags = {
    layer       = "silver"
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_storage_account" "gold" {
  name                            = local.gold_storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false

  tags = {
    layer       = "gold"
    workload    = var.workload
    environment = var.environment
  }
}

resource "azurerm_databricks_workspace" "main" {
  name                        = local.workspace_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = "premium"
  managed_resource_group_name = "${local.workspace_name}-mrg"
  public_network_access_enabled = true

  tags = {
    workload    = var.workload
    environment = var.environment
    isolation   = "per-layer"
  }
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = "ac-${var.workload}-${var.environment}-bronze-${local.region_abbreviation}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    layer = "bronze"
  }
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = "ac-${var.workload}-${var.environment}-silver-${local.region_abbreviation}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    layer = "silver"
  }
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = "ac-${var.workload}-${var.environment}-gold-${local.region_abbreviation}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    layer = "gold"
  }
}

resource "azuread_application" "bronze" {
  display_name = "sp-${var.workload}-${var.environment}-bronze"
}

resource "azuread_application" "silver" {
  display_name = "sp-${var.workload}-${var.environment}-silver"
}

resource "azuread_application" "gold" {
  display_name = "sp-${var.workload}-${var.environment}-gold"
}

resource "azuread_service_principal" "bronze" {
  client_id = azuread_application.bronze.client_id
}

resource "azuread_service_principal" "silver" {
  client_id = azuread_application.silver.client_id
}

resource "azuread_service_principal" "gold" {
  client_id = azuread_application.gold.client_id
}

resource "azurerm_role_assignment" "deployment_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}

resource "azurerm_role_assignment" "bronze_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.bronze.object_id
}

resource "azurerm_role_assignment" "silver_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.silver.object_id
}

resource "azurerm_role_assignment" "gold_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.gold.object_id
}

resource "azurerm_role_assignment" "bronze_connector_blob_contributor" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

resource "azurerm_role_assignment" "silver_connector_blob_contributor" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.silver.identity[0].principal_id
}

resource "azurerm_role_assignment" "gold_connector_blob_contributor" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.gold.identity[0].principal_id
}

resource "azurerm_role_assignment" "bronze_blob_contributor" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.bronze.object_id
}

resource "azurerm_role_assignment" "silver_source_reader" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.silver.object_id
}

resource "azurerm_role_assignment" "silver_blob_contributor" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.silver.object_id
}

resource "azurerm_role_assignment" "gold_source_reader" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.gold.object_id
}

resource "azurerm_role_assignment" "gold_blob_contributor" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.gold.object_id
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region

  tags = {
    architecture = "secure-medallion"
    environment  = var.environment
    workload     = var.workload
  }
}

resource "azurerm_storage_account" "bronze" {
  name                     = local.bronze_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  shared_access_key_enabled = true
  min_tls_version          = "TLS1_2"

  tags = {
    environment = var.environment
    layer       = "bronze"
    workload    = var.workload
  }
}

resource "azurerm_storage_account" "silver" {
  name                     = local.silver_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  shared_access_key_enabled = true
  min_tls_version          = "TLS1_2"

  tags = {
    environment = var.environment
    layer       = "silver"
    workload    = var.workload
  }
}

resource "azurerm_storage_account" "gold" {
  name                     = local.gold_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  shared_access_key_enabled = true
  min_tls_version          = "TLS1_2"

  tags = {
    environment = var.environment
    layer       = "gold"
    workload    = var.workload
  }
}

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
  public_network_access_enabled = true

  tags = {
    environment = var.environment
    workload    = var.workload
  }
}

resource "azurerm_databricks_workspace" "main" {
  name                        = local.workspace_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = var.databricks_workspace_sku
  public_network_access_enabled = true

  custom_parameters {
    no_public_ip = true
  }

  tags = {
    environment = var.environment
    workload    = var.workload
  }
}

resource "azurerm_databricks_access_connector" "bronze" {
  name                = local.bronze_access_connector_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    layer       = "bronze"
    workload    = var.workload
  }
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = local.silver_access_connector_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    layer       = "silver"
    workload    = var.workload
  }
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = local.gold_access_connector_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    layer       = "gold"
    workload    = var.workload
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

resource "azurerm_role_assignment" "bronze_storage_bronze_sp" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.bronze.object_id
}

resource "azurerm_role_assignment" "silver_storage_silver_sp" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.silver.object_id
}

resource "azurerm_role_assignment" "gold_storage_gold_sp" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.gold.object_id
}

resource "azurerm_role_assignment" "silver_reads_bronze" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.silver.object_id
}

resource "azurerm_role_assignment" "gold_reads_silver" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.gold.object_id
}

resource "azurerm_role_assignment" "bronze_storage_connector" {
  scope                = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

resource "azurerm_role_assignment" "silver_storage_connector" {
  scope                = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.silver.identity[0].principal_id
}

resource "azurerm_role_assignment" "gold_storage_connector" {
  scope                = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.gold.identity[0].principal_id
}

resource "azurerm_role_assignment" "bronze_key_vault_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.bronze.object_id
}

resource "azurerm_role_assignment" "silver_key_vault_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.silver.object_id
}

resource "azurerm_role_assignment" "gold_key_vault_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.gold.object_id
}

resource "azurerm_role_assignment" "deployment_key_vault_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sp_object_id
}
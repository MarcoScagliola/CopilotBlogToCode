# ================================================================================
# AZURE RESOURCES
# ================================================================================

resource "azurerm_resource_group" "blg" {
  name       = local.rg_name
  location   = local.azure_region
  tags       = local.common_tags
}

# ================================================================================
# STORAGE ACCOUNTS & CONTAINERS (Bronze, Silver, Gold)
# ================================================================================

resource "azurerm_storage_account" "bronze" {
  name                     = local.storage_account_bronze
  resource_group_name      = azurerm_resource_group.blg.name
  location                 = azurerm_resource_group.blg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true  # Enable Data Lake Gen2 (hierarchical namespace)
  https_traffic_only_enabled = true

  tags = local.common_tags
}

resource "azurerm_storage_account" "silver" {
  name                     = local.storage_account_silver
  resource_group_name      = azurerm_resource_group.blg.name
  location                 = azurerm_resource_group.blg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  https_traffic_only_enabled = true

  tags = local.common_tags
}

resource "azurerm_storage_account" "gold" {
  name                     = local.storage_account_gold
  resource_group_name      = azurerm_resource_group.blg.name
  location                 = azurerm_resource_group.blg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  https_traffic_only_enabled = true

  tags = local.common_tags
}

# Storage Containers
resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name               = local.storage_container_bronze
  storage_account_id = azurerm_storage_account.bronze.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "silver" {
  name               = local.storage_container_silver
  storage_account_id = azurerm_storage_account.silver.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "gold" {
  name               = local.storage_container_gold
  storage_account_id = azurerm_storage_account.gold.id
}

# ================================================================================
# KEY VAULT (for secrets)
# ================================================================================

resource "azurerm_key_vault" "blg" {
  name                = local.kv_name
  location            = azurerm_resource_group.blg.location
  resource_group_name = azurerm_resource_group.blg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
  enable_rbac_authorization   = true

  tags = local.common_tags
}

# RBAC: Current user as Key Vault Admin (to set secrets)
resource "azurerm_role_assignment" "kv_admin" {
  scope              = azurerm_key_vault.blg.id
  role_definition_name = "Key Vault Administrator"
  principal_id       = local.current_user_id
}

# Key Vault Secrets (JDBC credentials)
resource "azurerm_key_vault_secret" "jdbc_host" {
  name         = "jdbc-host"
  value        = var.jdbc_host
  key_vault_id = azurerm_key_vault.blg.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "jdbc_database" {
  name         = "jdbc-database"
  value        = var.jdbc_database
  key_vault_id = azurerm_key_vault.blg.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "jdbc_user" {
  name         = "jdbc-user"
  value        = var.jdbc_user
  key_vault_id = azurerm_key_vault.blg.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "jdbc_password" {
  name         = "jdbc-password"
  value        = var.jdbc_password
  key_vault_id = azurerm_key_vault.blg.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

# ================================================================================
# ENTRA ID SERVICE PRINCIPALS (Bronze, Silver, Gold)
# ================================================================================

resource "azuread_service_principal" "bronze" {
  client_id = azuread_application.bronze.client_id
  owners    = [local.current_user_id]
}

resource "azuread_service_principal" "silver" {
  client_id = azuread_application.silver.client_id
  owners    = [local.current_user_id]
}

resource "azuread_service_principal" "gold" {
  client_id = azuread_application.gold.client_id
  owners    = [local.current_user_id]
}

# Create applications for service principals
resource "azuread_application" "bronze" {
  display_name = local.sp_bronze_name
  owners       = [local.current_user_id]
}

resource "azuread_application" "silver" {
  display_name = local.sp_silver_name
  owners       = [local.current_user_id]
}

resource "azuread_application" "gold" {
  display_name = local.sp_gold_name
  owners       = [local.current_user_id]
}

# ================================================================================
# ROLE ASSIGNMENTS (SPs → Storage Accounts)
# ================================================================================

# Bronze SP: Storage Blob Data Contributor on Bronze Storage
resource "azurerm_role_assignment" "sp_bronze_on_storage_bronze" {
  scope              = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azuread_service_principal.bronze.object_id
}

# Silver SP: Storage Blob Data Contributor on Silver Storage
resource "azurerm_role_assignment" "sp_silver_on_storage_silver" {
  scope              = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azuread_service_principal.silver.object_id
}

# Gold SP: Storage Blob Data Contributor on Gold Storage
resource "azurerm_role_assignment" "sp_gold_on_storage_gold" {
  scope              = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azuread_service_principal.gold.object_id
}

# ================================================================================
# DATABRICKS ACCESS CONNECTORS (Managed Identity)
# ================================================================================

resource "azurerm_databricks_access_connector" "bronze" {
  name                = local.access_connector_bronze_name
  resource_group_name = azurerm_resource_group.blg.name
  location            = azurerm_resource_group.blg.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_databricks_access_connector" "silver" {
  name                = local.access_connector_silver_name
  resource_group_name = azurerm_resource_group.blg.name
  location            = azurerm_resource_group.blg.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_databricks_access_connector" "gold" {
  name                = local.access_connector_gold_name
  resource_group_name = azurerm_resource_group.blg.name
  location            = azurerm_resource_group.blg.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# RBAC: Access Connectors → Storage Accounts
resource "azurerm_role_assignment" "ac_bronze_on_storage_bronze" {
  scope              = azurerm_storage_account.bronze.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azurerm_databricks_access_connector.bronze.identity[0].principal_id
}

resource "azurerm_role_assignment" "ac_silver_on_storage_silver" {
  scope              = azurerm_storage_account.silver.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azurerm_databricks_access_connector.silver.identity[0].principal_id
}

resource "azurerm_role_assignment" "ac_gold_on_storage_gold" {
  scope              = azurerm_storage_account.gold.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azurerm_databricks_access_connector.gold.identity[0].principal_id
}

# ================================================================================
# DATABRICKS WORKSPACE & METASTORE
# ================================================================================

resource "azurerm_databricks_workspace" "blg" {
  name                = local.workspace_name
  resource_group_name = azurerm_resource_group.blg.name
  location            = azurerm_resource_group.blg.location
  sku                 = "premium"

  tags = local.common_tags

  depends_on = [
    azurerm_databricks_access_connector.bronze,
    azurerm_databricks_access_connector.silver,
    azurerm_databricks_access_connector.gold,
  ]
}

# Note: Metastore must be created separately via Databricks account console.
# This Terraform provider associates an existing metastore with the workspace.
resource "databricks_metastore_assignment" "blg" {
  provider             = databricks.workspace
  workspace_id         = azurerm_databricks_workspace.blg.workspace_id
  metastore_id         = var.databricks_metastore_id
  default_catalog_name = local.uc_catalog_bronze

  depends_on = [azurerm_databricks_workspace.blg]
}

# ================================================================================
# DATABRICKS AKV SECRET SCOPE (for JDBC credentials)
# ================================================================================

resource "databricks_secret_scope" "akv" {
  provider = databricks.workspace
  name     = local.secret_scope_name

  keyvault_metadata {
    resource_id = azurerm_key_vault.blg.id
    dns_name    = azurerm_key_vault.blg.vault_uri
  }

  depends_on = [databricks_metastore_assignment.blg]
}

# Secrets are created in Key Vault (above), automatically synced to Databricks scope

# ================================================================================
# UNITY CATALOG: STORAGE CREDENTIALS & EXTERNAL LOCATIONS (Bronze, Silver, Gold)
# ================================================================================

# Bronze
resource "databricks_storage_credential" "bronze" {
  provider = databricks.workspace
  name     = "${local.uc_catalog_bronze}_credential"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.bronze.id
  }

  depends_on = [databricks_secret_scope.akv]
}

resource "databricks_external_location" "bronze" {
  provider = databricks.workspace
  name     = "${local.uc_catalog_bronze}_external_location"

  url              = "abfss://${local.storage_container_bronze}@${azurerm_storage_account.bronze.name}.dfs.core.windows.net/"
  credential_name  = databricks_storage_credential.bronze.id
  comment          = "Bronze layer external location"

  depends_on = [databricks_storage_credential.bronze]
}

# Silver
resource "databricks_storage_credential" "silver" {
  provider = databricks.workspace
  name     = "${local.uc_catalog_silver}_credential"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.silver.id
  }

  depends_on = [databricks_secret_scope.akv]
}

resource "databricks_external_location" "silver" {
  provider = databricks.workspace
  name     = "${local.uc_catalog_silver}_external_location"

  url              = "abfss://${local.storage_container_silver}@${azurerm_storage_account.silver.name}.dfs.core.windows.net/"
  credential_name  = databricks_storage_credential.silver.id
  comment          = "Silver layer external location"

  depends_on = [databricks_storage_credential.silver]
}

# Gold
resource "databricks_storage_credential" "gold" {
  provider = databricks.workspace
  name     = "${local.uc_catalog_gold}_credential"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.gold.id
  }

  depends_on = [databricks_secret_scope.akv]
}

resource "databricks_external_location" "gold" {
  provider = databricks.workspace
  name     = "${local.uc_catalog_gold}_external_location"

  url              = "abfss://${local.storage_container_gold}@${azurerm_storage_account.gold.name}.dfs.core.windows.net/"
  credential_name  = databricks_storage_credential.gold.id
  comment          = "Gold layer external location"

  depends_on = [databricks_storage_credential.gold]
}

# ================================================================================
# UNITY CATALOG: CATALOGS & SCHEMAS
# ================================================================================

# Bronze Catalog
resource "databricks_catalog" "bronze" {
  provider       = databricks.workspace
  metastore_id   = var.databricks_metastore_id
  name           = local.uc_catalog_bronze
  comment        = "Bronze layer catalog (raw data)"
  external_location = databricks_external_location.bronze.id
  storage_root   = databricks_external_location.bronze.url
  owner          = "account users"

  properties = {
    "layer" = "bronze"
    "access_control" = "least_privilege"
  }

  depends_on = [databricks_external_location.bronze]
}

# Bronze Schema
resource "databricks_schema" "bronze" {
  provider       = databricks.workspace
  catalog_name   = databricks_catalog.bronze.name
  name           = local.uc_schema_bronze
  comment        = "Raw data schema (Bronze layer)"
  storage_location = "${databricks_external_location.bronze.url}${local.uc_schema_bronze}/"
  owner          = "account users"

  depends_on = [databricks_catalog.bronze]
}

# Silver Catalog
resource "databricks_catalog" "silver" {
  provider       = databricks.workspace
  metastore_id   = var.databricks_metastore_id
  name           = local.uc_catalog_silver
  comment        = "Silver layer catalog (curated data)"
  external_location = databricks_external_location.silver.id
  storage_root   = databricks_external_location.silver.url
  owner          = "account users"

  properties = {
    "layer" = "silver"
    "access_control" = "least_privilege"
  }

  depends_on = [databricks_external_location.silver]
}

# Silver Schema
resource "databricks_schema" "silver" {
  provider       = databricks.workspace
  catalog_name   = databricks_catalog.silver.name
  name           = local.uc_schema_silver
  comment        = "Curated data schema (Silver layer)"
  storage_location = "${databricks_external_location.silver.url}${local.uc_schema_silver}/"
  owner          = "account users"

  depends_on = [databricks_catalog.silver]
}

# Gold Catalog
resource "databricks_catalog" "gold" {
  provider       = databricks.workspace
  metastore_id   = var.databricks_metastore_id
  name           = local.uc_catalog_gold
  comment        = "Gold layer catalog (analytics-ready aggregates)"
  external_location = databricks_external_location.gold.id
  storage_root   = databricks_external_location.gold.url
  owner          = "account users"

  properties = {
    "layer" = "gold"
    "access_control" = "least_privilege"
  }

  depends_on = [databricks_external_location.gold]
}

# Gold Schema
resource "databricks_schema" "gold" {
  provider       = databricks.workspace
  catalog_name   = databricks_catalog.gold.name
  name           = local.uc_schema_gold
  comment        = "Aggregated analytics schema (Gold layer)"
  storage_location = "${databricks_external_location.gold.url}${local.uc_schema_gold}/"
  owner          = "account users"

  depends_on = [databricks_catalog.gold]
}

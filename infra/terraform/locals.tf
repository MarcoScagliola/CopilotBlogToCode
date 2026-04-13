locals {
  # Inputs
  workload        = var.workload
  environment     = var.environment
  azure_region    = var.azure_region
  current_user_id = data.azurerm_client_config.current.object_id

  # Region abbreviation mapping
  region_abbreviations = {
    "eastus"       = "eus"
    "westus"       = "wus"
    "westeurope"   = "weu"
    "northeurope"  = "neu"
    "uksouth"      = "uks"
    "ukwest"       = "ukw"
    "southeastasia" = "sea"
    "eastasia"     = "easia"
    "australiaeast" = "aue"
    "canadacentral" = "cac"
    "canadaeast"   = "cae"
    "japaneast"    = "jae"
    "japanwest"    = "jaw"
    "koreacentral" = "krc"
  }

  region_abbr = lookup(local.region_abbreviations, local.azure_region, "xxx")

  # ==================== Resource Names (CAF-aligned) ====================

  # Resource Group
  rg_name = "rg-${local.workload}-${local.environment}-${local.region_abbr}"

  # Databricks Workspace
  workspace_name = "dbw-${local.workload}-${local.environment}-${local.region_abbr}"

  # Key Vault
  kv_name = "kv-${local.workload}-${local.environment}-${local.region_abbr}"

  # Storage Accounts (Bronze, Silver, Gold) - Max 24 chars, no hyphens
  storage_account_bronze = "st${local.workload}brz${local.environment}"
  storage_account_silver = "st${local.workload}slv${local.environment}"
  storage_account_gold   = "st${local.workload}gld${local.environment}"

  # Storage Account Blob Containers
  storage_container_bronze = "raw"
  storage_container_silver = "curated"
  storage_container_gold   = "analytics"

  # Access Connectors (manage identity for UC)
  access_connector_bronze_name = "dbac-${local.workload}-brz-${local.environment}-${local.region_abbr}"
  access_connector_silver_name = "dbac-${local.workload}-slv-${local.environment}-${local.region_abbr}"
  access_connector_gold_name   = "dbac-${local.workload}-gld-${local.environment}-${local.region_abbr}"

  # Service Principals (Entra ID)
  sp_bronze_name = "sp-${local.workload}-bronze-${local.environment}-${local.region_abbr}"
  sp_silver_name = "sp-${local.workload}-silver-${local.environment}-${local.region_abbr}"
  sp_gold_name   = "sp-${local.workload}-gold-${local.environment}-${local.region_abbr}"

  # Unity Catalog Names
  uc_catalog_bronze = "${local.workload}_bronze"
  uc_catalog_silver = "${local.workload}_silver"
  uc_catalog_gold   = "${local.workload}_gold"

  # UC Schema Names
  uc_schema_bronze = "raw_data"
  uc_schema_silver = "curated_data"
  uc_schema_gold   = "analytics"

  # AKV Secret Scope (Databricks)
  secret_scope_name = "${local.workload}-${local.environment}-${local.region_abbr}-akv"

  # Job Names
  job_bronze_name      = "${local.workload}-bronze-ingest"
  job_silver_name      = "${local.workload}-silver-transform"
  job_gold_name        = "${local.workload}-gold-aggregate"
  job_orchestrator_name = "${local.workload}-orchestrator"

  # ==================== Tags ====================
  common_tags = merge(
    var.resource_tags,
    {
      Workload    = local.workload
      Environment = local.environment
      Region      = local.azure_region
      ManagedBy   = "Terraform"
    }
  )
}

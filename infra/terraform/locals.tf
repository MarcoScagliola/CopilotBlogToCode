locals {
  # ---------------------------------------------------------------------------
  # Region abbreviation map
  # ---------------------------------------------------------------------------
  region_abbreviation = {
    uksouth     = "uks"
    ukwest      = "ukw"
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
  }

  region_abbr = local.region_abbreviation[var.azure_region]

  # ---------------------------------------------------------------------------
  # Layer sets for for_each
  # ---------------------------------------------------------------------------
  layers = toset(["bronze", "silver", "gold"])

  layer_abbreviation = {
    bronze = "brz"
    silver = "slv"
    gold   = "gld"
  }

  # ---------------------------------------------------------------------------
  # Derived resource names (ALL names come from here – never hardcoded)
  # ---------------------------------------------------------------------------

  # Azure
  resource_group_name       = "rg-${var.workload}-${var.environment}-${local.region_abbr}"
  databricks_workspace_name = "dbw-${var.workload}-${var.environment}-${local.region_abbr}"
  key_vault_name            = "kv-${var.workload}-${var.environment}-${local.region_abbr}"

  # Per-layer: storage account names (no hyphens, max 24 chars, lowercase)
  storage_account_names = {
    for layer in local.layers :
    layer => "st${var.workload}${local.layer_abbreviation[layer]}${var.environment}"
  }

  # Per-layer: access connector names
  access_connector_names = {
    for layer in local.layers :
    layer => "dbac-${var.workload}-${local.layer_abbreviation[layer]}-${var.environment}-${local.region_abbr}"
  }

  # Per-layer: Entra application names
  entra_app_names = {
    for layer in local.layers :
    layer => "app-${var.workload}-${local.layer_abbreviation[layer]}-${var.environment}"
  }

  # UC: storage credential names
  storage_credential_names = {
    for layer in local.layers :
    layer => "sc-${var.workload}-${local.layer_abbreviation[layer]}-${var.environment}"
  }

  # UC: external location names
  external_location_names = {
    for layer in local.layers :
    layer => "el-${var.workload}-${local.layer_abbreviation[layer]}-${var.environment}"
  }

  # UC: catalog names (underscores, no hyphens)
  catalog_names = {
    for layer in local.layers :
    layer => "${var.workload}_${local.layer_abbreviation[layer]}_${var.environment}"
  }

  # UC: schema names
  schema_names = {
    bronze = "bronze_schema"
    silver = "silver_schema"
    gold   = "gold_schema"
  }

  # DAB: Lakeflow job names
  job_names = {
    for layer in local.layers :
    layer => "job-${var.workload}-${local.layer_abbreviation[layer]}-${var.environment}"
  }

  # Key Vault secret scope name for Databricks
  secret_scope_name = "kv-${var.workload}-${var.environment}"
}

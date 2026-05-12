locals {
  # ---------------------------------------------------------------------------
  # Region abbreviation — single source of truth.
  # Both locals.tf and generate_deploy_workflow.py must reference the same
  # mapping table. Any change here requires a matching change in the generator.
  # ---------------------------------------------------------------------------
  region_abbreviations = {
    uksouth       = "uks"
    eastus        = "eus"
    eastus2       = "eus2"
    westus        = "wus"
    westus2       = "wus2"
    westeurope    = "weu"
    northeurope   = "neu"
    australiaeast = "aue"
    southeastasia = "sea"
    centralus     = "cus"
  }
  region_abbrev = local.region_abbreviations[var.azure_region]

  # ---------------------------------------------------------------------------
  # Canonical resource names (terraform skill Section 5).
  # Pattern: <prefix>-{workload}-{environment}-{region_abbrev}
  # Storage accounts: no hyphens, lowercase, max 24 chars.
  # ---------------------------------------------------------------------------
  resource_group_name = "rg-${var.workload}-${var.environment}-${local.region_abbrev}"
  key_vault_name      = "kv-${var.workload}-${var.environment}-${local.region_abbrev}"
  workspace_name      = "dbw-${var.workload}-${var.environment}-${local.region_abbrev}"

  # Per-layer storage accounts (lowercase, no hyphens, max 24 chars)
  storage_accounts = {
    bronze = "st${var.workload}${var.environment}bronze${local.region_abbrev}"
    silver = "st${var.workload}${var.environment}silver${local.region_abbrev}"
    gold   = "st${var.workload}${var.environment}gold${local.region_abbrev}"
  }

  # Per-layer access connectors
  access_connectors = {
    bronze = "ac-${var.workload}-${var.environment}-bronze-${local.region_abbrev}"
    silver = "ac-${var.workload}-${var.environment}-silver-${local.region_abbrev}"
    gold   = "ac-${var.workload}-${var.environment}-gold-${local.region_abbrev}"
  }

  # Databricks secret scope name (one per environment)
  secret_scope_name = "kv-${var.environment}"

  # Per-layer Unity Catalog catalog names
  catalogs = {
    bronze = "bronze"
    silver = "silver"
    gold   = "gold"
  }

  # Per-layer Unity Catalog schema names (one schema per catalog)
  schemas = {
    bronze = "main"
    silver = "main"
    gold   = "main"
  }

  # Layer names as a static set — used for for_each to avoid plan-time unknowns.
  layers = toset(["bronze", "silver", "gold"])

  # ---------------------------------------------------------------------------
  # Identity mode — controls conditional resource creation.
  # ---------------------------------------------------------------------------
  create_layer_sps = var.layer_sp_mode == "create"

  # Per-layer service principal application names (only relevant in create mode)
  layer_sp_app_names = {
    bronze = "sp-${var.workload}-${var.environment}-bronze"
    silver = "sp-${var.workload}-${var.environment}-silver"
    gold   = "sp-${var.workload}-${var.environment}-gold"
  }

  # Resolved per-layer client IDs:
  # - create mode: use the newly created app registration's client ID
  # - existing mode: fall back to the single provided existing principal
  resolved_layer_client_ids = {
    for layer in local.layers :
    layer => local.create_layer_sps
      ? azuread_application.layer[layer].client_id
      : var.existing_layer_sp_client_id
  }

  # Resolved per-layer object IDs:
  # - create mode: use the Enterprise Application object ID of the created SP
  # - existing mode: use the supplied object ID
  resolved_layer_object_ids = {
    for layer in local.layers :
    layer => local.create_layer_sps
      ? azuread_service_principal.layer[layer].object_id
      : var.existing_layer_sp_object_id
  }

  # ---------------------------------------------------------------------------
  # Common tags applied to all resources
  # ---------------------------------------------------------------------------
  common_tags = {
    workload    = var.workload
    environment = var.environment
    region      = var.azure_region
    managed_by  = "terraform"
    source      = "blog-to-databricks-iac"
  }
}

locals {
  # ── Region abbreviation ──────────────────────────────────────────────────────
  # Extend this map when adding support for new regions.
  # Both locals.tf and generate_deploy_workflow.py must reference the same mapping.
  region_abbreviation = {
    "uksouth"        = "uks"
    "ukwest"         = "ukw"
    "eastus"         = "eus"
    "eastus2"        = "eu2"
    "westus"         = "wus"
    "westus2"        = "wu2"
    "westeurope"     = "weu"
    "northeurope"    = "neu"
    "australiaeast"  = "aue"
    "southeastasia"  = "sea"
  }

  region_abbrev = local.region_abbreviation[var.azure_region]

  # ── Canonical resource names ────────────────────────────────────────────────
  # Pattern: <prefix>-{workload}-{environment}-{region_abbrev}
  # Storage accounts: no hyphens, lowercase, max 24 chars.

  rg_name        = "rg-${var.workload}-${var.environment}-${local.region_abbrev}"
  kv_name        = "kv-${var.workload}-${var.environment}-${local.region_abbrev}"
  workspace_name = "dbw-${var.workload}-${var.environment}-${local.region_abbrev}"

  storage_name = {
    bronze = substr("st${var.workload}${var.environment}bronze${local.region_abbrev}", 0, 24)
    silver = substr("st${var.workload}${var.environment}silver${local.region_abbrev}", 0, 24)
    gold   = substr("st${var.workload}${var.environment}gold${local.region_abbrev}", 0, 24)
  }

  access_connector_name = {
    bronze = "ac-${var.workload}-${var.environment}-bronze-${local.region_abbrev}"
    silver = "ac-${var.workload}-${var.environment}-silver-${local.region_abbrev}"
    gold   = "ac-${var.workload}-${var.environment}-gold-${local.region_abbrev}"
  }

  sp_display_name = {
    bronze = "sp-${var.workload}-${var.environment}-bronze-${local.region_abbrev}"
    silver = "sp-${var.workload}-${var.environment}-silver-${local.region_abbrev}"
    gold   = "sp-${var.workload}-${var.environment}-gold-${local.region_abbrev}"
  }

  # ── Static layer set ─────────────────────────────────────────────────────────
  # Keys must be statically known at plan time (terraform skill — Iteration Shape rule).
  layers = toset(["bronze", "silver", "gold"])

  # ── Layer SP mode ─────────────────────────────────────────────────────────────
  create_layer_sps = var.layer_sp_mode == "create"

  # ── Resolved layer principal identifiers ─────────────────────────────────────
  # In create mode: sourced from the newly created azuread resources.
  # In existing mode: sourced from variable inputs (no Graph reads — restricted-tenant safe).
  resolved_layer_client_ids = local.create_layer_sps ? {
    bronze = azuread_application.layer["bronze"].client_id
    silver = azuread_application.layer["silver"].client_id
    gold   = azuread_application.layer["gold"].client_id
  } : {
    bronze = var.existing_layer_sp_client_id
    silver = var.existing_layer_sp_client_id
    gold   = var.existing_layer_sp_client_id
  }

  resolved_layer_object_ids = local.create_layer_sps ? {
    bronze = azuread_service_principal.layer["bronze"].object_id
    silver = azuread_service_principal.layer["silver"].object_id
    gold   = azuread_service_principal.layer["gold"].object_id
  } : {
    bronze = var.existing_layer_sp_object_id
    silver = var.existing_layer_sp_object_id
    gold   = var.existing_layer_sp_object_id
  }

  # ── Secret scope name ────────────────────────────────────────────────────────
  # Matches the scope name the bundle expects. One scope per environment.
  secret_scope_name = "kv-${var.environment}-scope"

  # ── Common tags ───────────────────────────────────────────────────────────────
  common_tags = {
    workload    = var.workload
    environment = var.environment
    region      = var.azure_region
    managed_by  = "terraform"
  }
}

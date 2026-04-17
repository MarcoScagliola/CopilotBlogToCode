locals {
  # ── Region abbreviation ──────────────────────────────────────────────────────
  region_abbrev = {
    uksouth       = "uks"
    ukwest        = "ukw"
    eastus        = "eus"
    eastus2       = "eus2"
    westus        = "wus"
    westus2       = "wus2"
    westeurope    = "weu"
    northeurope   = "neu"
    australiaeast = "aue"
  }
  region = lookup(local.region_abbrev, var.azure_region, var.azure_region)

  # ── Shared naming ────────────────────────────────────────────────────────────
  prefix = "${var.workload}-${var.environment}-${local.region}"

  # ── Resource names ───────────────────────────────────────────────────────────
  rg_name        = "rg-${local.prefix}"
  kv_name        = "kv-${local.prefix}"
  dbw_name       = "dbw-${local.prefix}"
  uc_metastore   = "uc-${local.prefix}"

  # Storage account names have a 24-char limit and no hyphens allowed.
  # Pattern: sa{workload}{layer}{environment}{region} (all lowercase)
  storage_names = {
    bronze = lower(replace("sa${var.workload}brz${var.environment}${local.region}", "-", ""))
    silver = lower(replace("sa${var.workload}slv${var.environment}${local.region}", "-", ""))
    gold   = lower(replace("sa${var.workload}gld${var.environment}${local.region}", "-", ""))
  }

  # Access Connector names (one per layer)
  access_connector_names = {
    bronze = "ac-${local.prefix}-bronze"
    silver = "ac-${local.prefix}-silver"
    gold   = "ac-${local.prefix}-gold"
  }

  # ── Layer configuration (order matters for orchestrator dependencies) ────────
  layers = ["bronze", "silver", "gold"]

  layer_configs = {
    for l in local.layers : l => {
      storage_name         = local.storage_names[l]
      access_connector_name = local.access_connector_names[l]
      catalog_name         = "${l}_${var.workload}_${var.environment}"
      schema_name          = "default"
    }
  }

  # ── Identity provisioning ────────────────────────────────────────────────────
  use_existing_layer_sp = var.layer_service_principal_mode == "existing"

  # When creating per-layer SPs, one application per layer is provisioned.
  # When reusing an existing SP, the for_each map is empty – no new apps are created.
  layer_apps_to_create = local.use_existing_layer_sp ? {} : local.layer_configs

  # Resolved SP application IDs (used for Databricks and RBAC assignments).
  layer_application_ids = local.use_existing_layer_sp ? {
    for l in local.layers : l => var.existing_layer_sp_client_id
  } : {
    for l in local.layers : l => azuread_application.layer[l].client_id
  }

  layer_sp_object_ids = local.use_existing_layer_sp ? {
    for l in local.layers : l => var.existing_layer_sp_object_id
  } : {
    for l in local.layers : l => azuread_service_principal.layer[l].object_id
  }

  # ── Key Vault secret-user assignments ────────────────────────────────────────
  # The deployment SP needs Secret User so it can create the AKV-backed secret scope.
  # Each layer SP also needs Secret User to read secrets at runtime.
  kv_secret_user_object_ids = distinct(concat(
    [var.azure_sp_object_id],
    values(local.layer_sp_object_ids)
  ))
}

locals {
  # ── Layers map (abbreviation used in resource names) ───────────────────────
  layers = {
    bronze = "brz"
    silver = "slv"
    gold   = "gld"
  }

  # ── Azure region abbreviation ──────────────────────────────────────────────
  region_abbr = {
    uksouth       = "uks"
    eastus        = "eus"
    eastus2       = "eu2"
    westus        = "wus"
    westus2       = "wu2"
    westeurope    = "weu"
    northeurope   = "neu"
    australiaeast = "aue"
    southeastasia = "sea"
    centralus     = "cus"
    canadacentral = "cac"
  }

  abbr = lookup(local.region_abbr, var.azure_region, substr(replace(var.azure_region, "-", ""), 0, 4))

  # ── Resource group ─────────────────────────────────────────────────────────
  resource_group_name = "rg-${var.workload}-${var.environment}-${local.abbr}"

  # ── Databricks workspace ───────────────────────────────────────────────────
  databricks_workspace_name = "dbw-${var.workload}-${var.environment}-${local.abbr}"

  # ── Key Vault (name ≤ 24 chars, alphanumeric + hyphens) ───────────────────
  key_vault_name = substr(
    replace("kv-${var.workload}-${var.environment}-${local.abbr}", "_", "-"),
    0,
    24
  )

  # ── Per-layer resource names ───────────────────────────────────────────────
  # Storage account names: max 24 chars, lowercase alphanumeric only
  storage_account_names = {
    for layer, abbr_layer in local.layers :
    layer => lower(substr(
      replace("st${abbr_layer}${var.workload}${var.environment}${local.abbr}", "-", ""),
      0,
      24
    ))
  }

  # Access connector names
  access_connector_names = {
    for layer, abbr_layer in local.layers :
    layer => "ac-${abbr_layer}-${var.workload}-${var.environment}-${local.abbr}"
  }

  # Unity Catalog catalog names
  catalog_names = {
    for layer, abbr_layer in local.layers :
    layer => "${var.environment}_${layer}"
  }

  # Unity Catalog schema names
  schema_names = {
    bronze = "ingestion"
    silver = "refined"
    gold   = "curated"
  }

  # Secret scope name (AKV-backed)
  secret_scope_name = "kv-${var.environment}-scope"
}

locals {
  # ---------------------------------------------------------------------------
  # Region abbreviation
  # Must match the mapping table in generate_deploy_workflow.py exactly.
  # Both sides are updated atomically; validate_workflow_parity.sh catches drift.
  # ---------------------------------------------------------------------------
  region_abbreviation = {
    "australiaeast"   = "aue"
    "australiasouth"  = "aus"
    "brazilsouth"     = "brs"
    "canadacentral"   = "cac"
    "canadaeast"      = "cae"
    "centralus"       = "cus"
    "eastasia"        = "eas"
    "eastus"          = "eus"
    "eastus2"         = "eu2"
    "francecentral"   = "frc"
    "germanywestcentral" = "gwc"
    "japaneast"       = "jae"
    "koreacentral"    = "koc"
    "northeurope"     = "neu"
    "norwayeast"      = "noe"
    "southafricanorth" = "san"
    "southcentralus"  = "scu"
    "southeastasia"   = "sea"
    "swedencentral"   = "swc"
    "switzerlandnorth" = "swn"
    "uaenorth"        = "uan"
    "uksouth"         = "uks"
    "ukwest"          = "ukw"
    "westeurope"      = "weu"
    "westus"          = "wus"
    "westus2"         = "wu2"
    "westus3"         = "wu3"
  }

  abbrev = local.region_abbreviation[var.azure_region]

  # ---------------------------------------------------------------------------
  # Canonical resource names — Section 5 of the terraform skill.
  # Pattern: <prefix>-{workload}-{environment}-{abbrev}
  # Storage accounts: no hyphens, all lowercase, truncated to 24 chars.
  # ---------------------------------------------------------------------------
  rg_name        = "rg-${var.workload}-${var.environment}-${local.abbrev}"
  kv_name        = substr("kv-${var.workload}-${var.environment}-${local.abbrev}", 0, 24)
  workspace_name = "dbw-${var.workload}-${var.environment}-${local.abbrev}"

  storage_names = {
    bronze = substr("st${var.workload}${var.environment}bronze${local.abbrev}", 0, 24)
    silver = substr("st${var.workload}${var.environment}silver${local.abbrev}", 0, 24)
    gold   = substr("st${var.workload}${var.environment}gold${local.abbrev}", 0, 24)
  }

  access_connector_names = {
    bronze = "ac-${var.workload}-${var.environment}-bronze-${local.abbrev}"
    silver = "ac-${var.workload}-${var.environment}-silver-${local.abbrev}"
    gold   = "ac-${var.workload}-${var.environment}-gold-${local.abbrev}"
  }

  # Used for Entra ID app display names when layer_sp_mode = "create".
  sp_display_names = {
    bronze = "sp-${var.workload}-${var.environment}-bronze-${local.abbrev}"
    silver = "sp-${var.workload}-${var.environment}-silver-${local.abbrev}"
    gold   = "sp-${var.workload}-${var.environment}-gold-${local.abbrev}"
  }

  # ---------------------------------------------------------------------------
  # Layer set — static keys so for_each on downstream resources is plan-time safe.
  # ---------------------------------------------------------------------------
  layers = toset(["bronze", "silver", "gold"])

  # ---------------------------------------------------------------------------
  # Layer SP mode flag — drives conditional resource creation.
  # ---------------------------------------------------------------------------
  create_layer_sps = var.layer_sp_mode == "create"

  # ---------------------------------------------------------------------------
  # Resolved layer principal identifiers.
  # In "create" mode: read from the created azuread_service_principal resources.
  # In "existing" mode: taken from operator-supplied variables.
  # The ternary resolves at apply time; the for_each keys that drive iteration
  # are always static (local.layers), so plan-time knowability is preserved.
  # ---------------------------------------------------------------------------
  resolved_layer_client_ids = {
    for layer in local.layers :
    layer => local.create_layer_sps
      ? azuread_application.layer[layer].client_id
      : var.existing_layer_sp_client_id
  }

  resolved_layer_object_ids = {
    for layer in local.layers :
    layer => local.create_layer_sps
      ? azuread_service_principal.layer[layer].object_id
      : var.existing_layer_sp_object_id
  }

  # ---------------------------------------------------------------------------
  # Secret scope name — one per environment as recommended by the article.
  # ---------------------------------------------------------------------------
  secret_scope_name = "kv-${var.environment}-scope"

  # ---------------------------------------------------------------------------
  # Common tags applied to all resources.
  # ---------------------------------------------------------------------------
  common_tags = {
    workload    = var.workload
    environment = var.environment
    managed_by  = "terraform"
  }
}

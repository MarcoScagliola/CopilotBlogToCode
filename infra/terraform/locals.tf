locals {
  region_abbreviations = {
    uksouth      = "uks"
    ukwest       = "ukw"
    westeurope   = "weu"
    northeurope  = "neu"
    eastus       = "eus"
    eastus2      = "eus2"
    westus2      = "wus2"
    centralus    = "cus"
    southcentral = "scu"
  }

  region_abbreviation = lookup(local.region_abbreviations, lower(var.azure_region), lower(replace(var.azure_region, " ", "")))

  layer_abbreviations = {
    bronze       = "brz"
    silver       = "slv"
    gold         = "gld"
    orchestrator = "orch"
  }

  normalized_workload = lower(replace(var.workload, "-", ""))
  normalized_env      = lower(replace(var.environment, "-", ""))

  resource_group_name  = "rg-${local.normalized_workload}-${local.normalized_env}-${local.region_abbreviation}"
  databricks_workspace = "dbw-${local.normalized_workload}-${local.normalized_env}-${local.region_abbreviation}"
  key_vault_name       = substr("kv-${local.normalized_workload}-${local.normalized_env}-${local.region_abbreviation}", 0, 24)
  secret_scope_name    = "scope-${local.normalized_workload}-${local.normalized_env}"

  storage_account_names = {
    bronze = substr("st${local.normalized_workload}${local.layer_abbreviations.bronze}${local.normalized_env}", 0, 24)
    silver = substr("st${local.normalized_workload}${local.layer_abbreviations.silver}${local.normalized_env}", 0, 24)
    gold   = substr("st${local.normalized_workload}${local.layer_abbreviations.gold}${local.normalized_env}", 0, 24)
  }

  access_connector_names = {
    bronze = "dbac-${local.normalized_workload}-${local.layer_abbreviations.bronze}-${local.normalized_env}-${local.region_abbreviation}"
    silver = "dbac-${local.normalized_workload}-${local.layer_abbreviations.silver}-${local.normalized_env}-${local.region_abbreviation}"
    gold   = "dbac-${local.normalized_workload}-${local.layer_abbreviations.gold}-${local.normalized_env}-${local.region_abbreviation}"
  }

  application_names = {
    bronze = "app-${local.normalized_workload}-${local.layer_abbreviations.bronze}-${local.normalized_env}"
    silver = "app-${local.normalized_workload}-${local.layer_abbreviations.silver}-${local.normalized_env}"
    gold   = "app-${local.normalized_workload}-${local.layer_abbreviations.gold}-${local.normalized_env}"
  }

  storage_credential_names = {
    bronze = "sc-${local.normalized_workload}-${local.layer_abbreviations.bronze}-${local.normalized_env}"
    silver = "sc-${local.normalized_workload}-${local.layer_abbreviations.silver}-${local.normalized_env}"
    gold   = "sc-${local.normalized_workload}-${local.layer_abbreviations.gold}-${local.normalized_env}"
  }

  external_location_names = {
    bronze = "el-${local.normalized_workload}-${local.layer_abbreviations.bronze}-${local.normalized_env}"
    silver = "el-${local.normalized_workload}-${local.layer_abbreviations.silver}-${local.normalized_env}"
    gold   = "el-${local.normalized_workload}-${local.layer_abbreviations.gold}-${local.normalized_env}"
  }

  catalog_names = {
    bronze = "${local.normalized_workload}_${local.layer_abbreviations.bronze}_${local.normalized_env}"
    silver = "${local.normalized_workload}_${local.layer_abbreviations.silver}_${local.normalized_env}"
    gold   = "${local.normalized_workload}_${local.layer_abbreviations.gold}_${local.normalized_env}"
  }

  schema_names = {
    bronze = "bronze_schema"
    silver = "silver_schema"
    gold   = "gold_schema"
  }

  common_tags = merge(var.tags, {
    workload     = local.normalized_workload
    environment  = local.normalized_env
    region       = lower(var.azure_region)
    architecture = "secure-medallion"
  })
}
locals {
  region_abbreviations = {
    uksouth     = "uks"
    ukwest      = "ukw"
    westeurope  = "weu"
    northeurope = "neu"
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
  }

  workload_slug       = replace(replace(replace(lower(var.workload), "-", ""), "_", ""), " ", "")
  environment_slug    = replace(replace(replace(lower(var.environment), "-", ""), "_", ""), " ", "")
  region_abbreviation = lookup(local.region_abbreviations, lower(var.azure_region), replace(replace(replace(lower(var.azure_region), "-", ""), "_", ""), " ", ""))

  layer_configs = {
    bronze = {
      short          = "brz"
      catalog_suffix = "brz"
      schema_name    = "bronze_schema"
      runtime_engine = "STANDARD"
    }
    silver = {
      short          = "slv"
      catalog_suffix = "slv"
      schema_name    = "silver_schema"
      runtime_engine = "PHOTON"
    }
    gold = {
      short          = "gld"
      catalog_suffix = "gld"
      schema_name    = "gold_schema"
      runtime_engine = "STANDARD"
    }
  }

  upstream_layers = {
    silver = "bronze"
    gold   = "silver"
  }

  resource_group_name         = "rg-${local.workload_slug}-${local.environment_slug}-${local.region_abbreviation}"
  databricks_workspace_name   = "dbw-${local.workload_slug}-${local.environment_slug}-${local.region_abbreviation}"
  managed_resource_group_name = "rg-${local.workload_slug}-${local.environment_slug}-${local.region_abbreviation}-dbx"
  key_vault_name              = substr("kv-${local.workload_slug}-${local.environment_slug}-${local.region_abbreviation}", 0, 24)
  secret_scope_name           = var.secret_scope_name != "" ? var.secret_scope_name : local.key_vault_name
  storage_container_name      = "data"

  tags = merge({
    architecture = "secure-medallion"
    environment  = local.environment_slug
    managed_by   = "terraform"
    region       = lower(var.azure_region)
    workload     = local.workload_slug
  }, var.tags)

  storage_account_names = {
    for layer, config in local.layer_configs :
    layer => substr("st${local.workload_slug}${config.short}${local.environment_slug}", 0, 24)
  }

  layer_names = {
    for layer, config in local.layer_configs :
    layer => {
      access_connector   = "dbac-${local.workload_slug}-${config.short}-${local.environment_slug}-${local.region_abbreviation}"
      application        = "app-${local.workload_slug}-${config.short}-${local.environment_slug}"
      catalog            = "${local.workload_slug}_${config.catalog_suffix}_${local.environment_slug}"
      external_location  = "el-${local.workload_slug}-${config.short}-${local.environment_slug}"
      job                = "job-${local.workload_slug}-${config.short}-${local.environment_slug}"
      schema             = config.schema_name
      storage_credential = "sc-${local.workload_slug}-${config.short}-${local.environment_slug}"
    }
  }

  jdbc_secret_values = {
    jdbc-host     = var.jdbc_host
    jdbc-database = var.jdbc_database
    jdbc-user     = var.jdbc_user
    jdbc-password = var.jdbc_password
  }
}
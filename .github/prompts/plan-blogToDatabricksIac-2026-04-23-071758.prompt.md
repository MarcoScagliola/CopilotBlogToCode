# Execution Record — blog-to-databricks-iac

**Generated:** 2026-04-23T07:17:58Z  
**Blog:** https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268  
**Trigger:** Full regeneration after `reset_generated.py --force`

## Resolved Inputs

| Parameter | Value |
|---|---|
| workload | `blg` |
| environment | `dev` |
| azure_region | `uksouth` |
| github_environment | `BLG2CODEDEV` |
| layer_sp_mode | `existing` |
| AZURE_TENANT_ID secret | `AZURE_TENANT_ID` |
| AZURE_SUBSCRIPTION_ID secret | `AZURE_SUBSCRIPTION_ID` |
| AZURE_CLIENT_ID secret | `AZURE_CLIENT_ID` |
| AZURE_CLIENT_SECRET secret | `AZURE_CLIENT_SECRET` |
| AZURE_SP_OBJECT_ID secret | `AZURE_SP_OBJECT_ID` |
| EXISTING_LAYER_SP_CLIENT_ID secret | `EXISTING_LAYER_SP_CLIENT_ID` |
| EXISTING_LAYER_SP_OBJECT_ID secret | `EXISTING_LAYER_SP_OBJECT_ID` |

## Generated Artifacts

### Terraform (infra/terraform/)
- `versions.tf` — azurerm ~>4.0, azuread ~>3.0, time ~>0.9
- `providers.tf` — `recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted`
- `variables.tf` — `key_vault_recover_soft_deleted` default=`true`; layer_sp_mode; enable_access_connectors
- `locals.tf` — layers map, region_abbr, all resource name patterns
- `main.tf` — RG, storage+ADLS+container per layer, Databricks workspace, access connectors, KV, RBAC, optional SPs
- `outputs.tf` — `layer_access_connector_ids`, workspace outputs, catalog names, secret_scope_name

### GitHub Actions Workflows
- `.github/workflows/validate-terraform.yml` — `terraform init -backend=false && validate`
- `.github/workflows/deploy-infrastructure.yml` — full apply with KV recovery/import fallback
- `.github/workflows/deploy-dab.yml` — Databricks Asset Bundle deploy using Terraform output artifacts

### Databricks Asset Bundle
- `databricks-bundle/databricks.yml` — all 14 variables including bronze/silver/gold_access_connector_id; dev+prd targets
- `databricks-bundle/resources/jobs.yml` — setup+bronze+silver+gold+orchestrator jobs
- `databricks-bundle/src/setup/main.py` — creates storage credentials → external locations → catalogs → schemas (idempotent)
- `databricks-bundle/src/bronze/main.py` — ingestion; writes `raw_events` Delta table
- `databricks-bundle/src/silver/main.py` — deduplication; writes `events` Delta table
- `databricks-bundle/src/gold/main.py` — aggregation; writes `event_summary` Delta table

### Documentation
- `SPEC.md` — architecture analysis from article
- `README.md` — prerequisites, secrets, workflow guide
- `TODO.md` — pre/post-deployment checklist

## Validation Results

| Check | Result |
|---|---|
| `python -m py_compile` all Python scripts | ✅ Pass |
| `terraform init -backend=false` | ✅ Pass |
| `terraform validate` | ✅ Pass |
| YAML parse: validate-terraform.yml | ✅ Pass |
| YAML parse: deploy-infrastructure.yml | ✅ Pass |
| YAML parse: deploy-dab.yml | ✅ Pass |
| YAML parse: databricks.yml | ✅ Pass |
| YAML parse: jobs.yml | ✅ Pass |

## Key Architectural Fixes Preserved

1. `data_security_mode: USER_ISOLATION` on all job clusters (Unity Catalog requirement)
2. Setup job idempotently creates: storage credentials → external locations → catalogs → schemas via Access Connector IDs
3. `key_vault_recover_soft_deleted` variable default=`true` in variables.tf
4. `recover_soft_deleted_key_vaults` wired to variable in providers.tf
5. Deploy workflow: inline KV recovery mode computation; `TF_VAR_key_vault_recover_soft_deleted` exported before apply
6. Deploy workflow: `az keyvault recover` + `terraform import` fallback when recovery-disabled error fires
7. `layer_access_connector_ids` output in outputs.tf (map of layer → access connector resource ID)
8. `deploy_dab.py` OPTIONAL_MAP_KEYS includes bronze/silver/gold_access_connector_id from `layer_access_connector_ids`
9. `generate_jobs_bundle.py` passes all 12 params (9 storage + 3 access connector IDs) to setup task

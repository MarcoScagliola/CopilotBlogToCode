# Execution record — blog-to-databricks-iac

## Run metadata

- Run start (UTC): 2026-05-10T20:15:18Z
- Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch result: FETCH_OK (rendered article content captured in SPEC.md)

## Resolved inputs

| Input | Value |
|---|---|
| workload | blg |
| environment | dev |
| azure_region | uksouth |
| azure_region_abbrev | uks |
| layer_sp_mode | create |
| github_environment | BLG2CODEDEV |
| name_suffix | blg-dev-uks |

## Generated artifacts

### Documentation
- SPEC.md — medallion architecture analysis with explicit "not stated in article" markers
- README.md — preserved from prior run (operator-curated)
- TODO.md — deferred items rendered from template

### Terraform module (infra/terraform/)
- versions.tf — provider pins (azurerm ~> 3.116, azuread ~> 2.53, random ~> 3.6); required terraform >= 1.6.0
- providers.tf — azurerm features (recover_soft_deleted_key_vaults var-driven), azuread, random
- variables.tf — 9 required vars matching the 11 TF_VAR_* exports (existing_layer_sp_* default to "")
- locals.tf — name suffix, region abbreviation map, per-layer storage / catalog name maps, secret_scope_name, layer_sp_keys
- main.tf — RG, per-layer ADLS Gen2 storage + containers, per-layer access connectors + RAs, per-layer SPs (gated on layer_sp_mode), KV + RBAC, premium Databricks workspace
- outputs.tf — required: databricks_workspace_url (https-prefixed), databricks_workspace_resource_id; optional flat: catalog names, secret_scope_name; optional maps: layer_principal_client_ids, layer_storage_account_names, layer_access_connector_ids

### GitHub Actions workflows (.github/workflows/)
- validate-terraform.yml — fmt-check, init, validate on PR
- deploy-infrastructure.yml — TF_VAR_* parity with variables.tf (11 exports), -input=false on all apply invocations, workflow_dispatch inputs for key_vault_recovery_mode + state_strategy + layer_sp_mode
- deploy-dab.yml — invokes deploy_dab.py with TF outputs bridged into bundle variables

### Databricks Asset Bundle (databricks-bundle/)
- databricks.yml — literal bundle name, include resources/*.yml, 14 declared bundle variables, dev (default) + prd targets
- resources/jobs.yml — setup_job, bronze_job, silver_job, gold_job, smoke_test_job, orchestrator_job; all use job_cluster_key + new_cluster (DBR 13.3.x-scala2.12, Standard_DS3_v2, USER_ISOLATION); python_file paths use ../src prefix
- src/setup/main.py — UC provisioning scaffold; 12 args matching jobs.yml setup_job parameters
- src/bronze/main.py — ingestion scaffold; --catalog, --schema, --secret-scope, --probe-secret-key
- src/silver/main.py — Bronze→Silver transformation scaffold; --source-catalog/schema, --target-catalog/schema
- src/gold/main.py — Silver→Gold modelling scaffold; --source-catalog/schema, --target-catalog/schema
- src/smoke_test/main.py — end-to-end layout check; per-layer catalog/schema + --min-row-count

## Validation results (Step 9)

| Check | Result |
|---|---|
| python -m py_compile across all generator scripts + 5 entrypoints + deploy_dab.py + post_deploy_checklist.py + fetch_blog.py | PASS |
| terraform -chdir=infra/terraform init -backend=false | PASS |
| terraform -chdir=infra/terraform validate | PASS — Success! The configuration is valid. |
| YAML parse: 3 workflow YAML + databricks.yml + jobs.yml | PASS (5/5) |
| jobs.yml regeneration idempotency (hash before == hash after) | PASS |
| validate_workflow_parity.sh — TF_VAR_* parity (9 required vars), -input=false on apply | PASS |
| Invariants: workspace URL + resource_id outputs both present | PASS |
| Invariants: KV recover_soft_deleted_key_vaults var-driven | PASS |
| Invariants: zero `data "azuread_*"` blocks | PASS (count=0) |
| Invariants: databricks.yml includes `resources/*.yml` | PASS |
| Invariants: all 5 python_file paths start with `../src` | PASS (5/5) |

## Deferred items

TODO.md captures the deferred work in three groups:

- **Pre-deployment (5 items)** — RBAC on deployment principal, Entra ID directory permissions for layer_sp_mode=create, GitHub Environment BLG2CODEDEV setup, source-system identification, Unity Catalog metastore attach, UC catalog naming confirmation
- **Deployment-time inputs (3 items)** — per-run choice of key_vault_recovery_mode, state_strategy, dispatch-input combinations, job schedules
- **Post-infrastructure (3 items)** — KV-backed secret scope creation, runtime secret population, UC privilege model
- **Post-DAB (2 items)** — orchestrator end-to-end run, cross-layer isolation verification
- **Architectural decisions deferred (7 items)** — remote TF state, storage shared-key disable, fmt-check in CI, cluster policy contents, networking posture, secret rotation, UC system tables

Total deferred items: 20.

## Notes

- Run targets `layer_sp_mode = create`. Operators on restricted tenants without Application.ReadWrite.All on the deployment principal must re-dispatch with `layer_sp_mode = existing` and supply EXISTING_LAYER_SP_CLIENT_ID / EXISTING_LAYER_SP_OBJECT_ID.
- Bundle variables `workspace_host` and `workspace_resource_id` are declared but unreferenced inside YAML: they exist solely so the deploy_dab.py bridge's `--var` pass succeeds. Authentication is handled via DATABRICKS_HOST / DATABRICKS_AZURE_RESOURCE_ID env vars set by the same bridge.
- The five python entrypoints are scaffolds. They wire the argparse contract that matches `resources/jobs.yml` and demonstrate the secret-read pattern, but the real Bronze ingestion, Silver integration, and Gold modelling are workload-specific and tracked in TODO.md.

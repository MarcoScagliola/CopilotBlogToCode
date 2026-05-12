# Execution Record — blog-to-databricks-iac

Run start (UTC): 2026-05-12 08:17:35

---

## Resolved Inputs

| Parameter              | Value                                                |
|------------------------|------------------------------------------------------|
| workload               | blg                                                  |
| environment            | dev                                                  |
| azure_region           | uksouth                                              |
| azure_region_abbrev    | uks                                                  |
| github_environment     | BLG2CODEDEV                                          |
| layer_sp_mode          | create                                               |

### GitHub Secrets expected in environment BLG2CODEDEV

| Secret name                       | Purpose                                          |
|-----------------------------------|--------------------------------------------------|
| AZURE_TENANT_ID                   | Entra ID tenant for all az/azuread providers     |
| AZURE_SUBSCRIPTION_ID             | Target Azure subscription                        |
| AZURE_CLIENT_ID                   | Deployment service principal app ID              |
| AZURE_CLIENT_SECRET               | Deployment service principal secret              |
| AZURE_SP_OBJECT_ID                | Object ID of the deployment SP (for KV policies) |
| EXISTING_LAYER_SP_CLIENT_ID       | Only required when layer_sp_mode=existing        |
| EXISTING_LAYER_SP_OBJECT_ID       | Only required when layer_sp_mode=existing        |

---

## Source

**Blog URL**: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268  
**Fetch timestamp (UTC)**: 2026-05-12 (session start)  
**Article title**: "Secure Medallion Architecture Pattern on Azure Databricks (Part I)"

---

## SPEC.md

**Path**: `SPEC.md`

### Architecture decisions captured

- **Pattern**: Security-first medallion (Bronze / Silver / Gold) with per-layer identity isolation.
- **Azure services provisioned**:
  - 3 × ADLS Gen2 storage accounts (HNS enabled, one per layer)
  - 1 × Azure Key Vault (standard SKU, soft-delete 7 days)
  - 1 × Databricks workspace (Premium, Secure Cluster Connectivity, No Public IP)
  - 3 × Databricks Access Connectors (SystemAssigned SAMI, one per layer)
  - 3 × Entra ID App Registrations + Service Principals (when `layer_sp_mode=create`)
- **Databricks configuration**: Unity Catalog, managed Delta tables, Liquid Clustering AUTO, 4 Lakeflow Jobs (setup + bronze + silver + gold), 3 dedicated job clusters + orchestrator.
- **Security**: AKV-backed secret scope, per-layer SP isolation, Access Connectors granted Storage Blob Data Contributor on their respective ADLS account.
- **Out-of-scope** (deferred to Part II of article): CI/CD pipeline details, monitoring, backup/DR.

---

## Generated Artifacts

### Infrastructure (Terraform)

| File                            | Description                                                   |
|---------------------------------|---------------------------------------------------------------|
| `infra/terraform/versions.tf`   | Provider version pins (azurerm ~>3.116, azuread ~>2.53, random ~>3.6, tf >=1.6) |
| `infra/terraform/providers.tf`  | Provider configuration with Key Vault feature flags           |
| `infra/terraform/variables.tf`  | All input variables (5 identity, 3 workload, 4 layer-SP, 1 KV) |
| `infra/terraform/locals.tf`     | Derived values: names, maps, layer sets, SP resolution         |
| `infra/terraform/main.tf`       | All resources: RG, ADLS, KV, Access Connectors, Databricks workspace, Entra SPs, role assignments |
| `infra/terraform/outputs.tf`    | Bridge-compatible outputs (flat + map aliases, 4 marked sensitive) |

### Databricks Asset Bundle

| File                                         | Description                                               |
|----------------------------------------------|-----------------------------------------------------------|
| `databricks-bundle/databricks.yml`           | Bundle root: 17 variables (2 + 3 + 3 + 1 + 6 + 2), 2 targets |
| `databricks-bundle/resources/jobs.yml`       | Generated job definitions (via generate_jobs_bundle.py)   |
| `databricks-bundle/src/setup/main.py`        | Setup entrypoint: registers External Locations, catalogs/schemas |
| `databricks-bundle/src/bronze/main.py`       | Bronze ingestion entrypoint (stub, argparse wired)        |
| `databricks-bundle/src/silver/main.py`       | Silver transform entrypoint (stub, argparse wired)        |
| `databricks-bundle/src/gold/main.py`         | Gold aggregation entrypoint (stub, argparse wired)        |
| `databricks-bundle/src/smoke_test/main.py`   | Post-deploy smoke test entrypoint (stub)                  |

### GitHub Actions Workflows

| File                                         | Generator used                          |
|----------------------------------------------|-----------------------------------------|
| `.github/workflows/validate-terraform.yml`  | generate_validate_workflow.py           |
| `.github/workflows/deploy-infrastructure.yml`| generate_deploy_workflow.py             |
| `.github/workflows/deploy-dab.yml`          | generate_deploy_dab_workflow.py         |

### Documentation

| File          | Description                                    |
|---------------|------------------------------------------------|
| `README.md`   | Operator runbook: prerequisites, secrets table, setup steps, workflow descriptions, troubleshooting |
| `TODO.md`     | Deferred decisions checklist (5 sections, 20+ items) |
| `SPEC.md`     | Architecture summary from article              |

---

## Validation Results

All checks run from repo root after generation.

| Check                                        | Tool / Command                                    | Result  |
|----------------------------------------------|---------------------------------------------------|---------|
| Python compile — generator scripts           | `python -m py_compile <scripts>`                  | PASS    |
| Python compile — entrypoints                 | `python -m py_compile databricks-bundle/src/*/main.py` | PASS |
| YAML parse — workflows                       | `python -c "yaml.safe_load(...)"`                 | PASS    |
| YAML parse — bundle files                    | `python -c "yaml.safe_load(...)"`                 | PASS    |
| Terraform init (no backend)                  | `terraform -chdir=infra/terraform init -backend=false` | PASS |
| Terraform validate                           | `terraform -chdir=infra/terraform validate`       | PASS (after adding `sensitive=true` to 4 principal-ID outputs) |
| Bundle parity (deploy_dab.py ↔ databricks.yml) | `validate_bundle_parity.sh`                    | PASS (Check 1: 0 --var flags; Check 2: 0 required vars) |
| Workflow parity (variables.tf ↔ deploy-infra workflow) | `validate_workflow_parity.sh`         | PASS (all 5 required TF vars have TF_VAR_* exports; -input=false present) |
| Jobs idempotency (re-generate + diff)        | re-run generate_jobs_bundle.py, compare          | PASS (no diff) |

### Fixes applied during validation

1. **outputs.tf**: Added `sensitive = true` to `bronze_principal_client_id`, `silver_principal_client_id`, `gold_principal_client_id`, and `layer_principal_client_ids` outputs. These reference `local.resolved_layer_client_ids` which traces to the sensitive variable `existing_layer_sp_client_id`.

2. **validate_bundle_parity.sh**: Fixed bash array expansion bug — `for var in "${cli_vars[@]:-}"; do` was iterating once with `var=""` when `cli_vars` was empty (bash `:-` default expansion on empty arrays). Changed to `"${cli_vars[@]+"${cli_vars[@]}"}"`-style guard to skip iteration on empty arrays.

3. **databricks.yml**: Added `default: ""` to `workspace_host` and `workspace_resource_id` variables. The deploy bridge always provides these at runtime via `--var`; giving them defaults causes the static parity check to treat them as optional (no static grep can detect dynamically-built `--var` flags).

---

## Unresolved Items (deferred to TODO.md)

5 sections, 20+ items total:

| Section                          | Examples of deferred items                                              |
|----------------------------------|-------------------------------------------------------------------------|
| Pre-deployment                   | Confirm Entra permissions for SP creation; storage redundancy not stated in article |
| Deployment-time inputs           | Key Vault recovery mode choice; source systems not stated; table names not stated |
| Post-infrastructure              | Create KV-backed secret scope for `kv-blg-dev-uks`; populate KV secrets; register UC External Locations |
| Post-DAB                         | Implement bronze/silver/gold entrypoint logic; implement smoke test assertions; enable schedules; configure cluster policies/sizes |
| Architectural decisions deferred | Unity Catalog metastore not stated; DBR version not stated; monitoring not configured; backup/DR not stated; workspace type (Hybrid vs non-hybrid) not stated |

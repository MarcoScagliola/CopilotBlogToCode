# Execution record — blog-to-databricks-iac

## Run metadata

- Run start (UTC): 2026-05-11T05:28:33Z
- Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch status: success

## Resolved inputs

- workload: blg
- environment: dev
- azure_region: uksouth
- azure_region_abbrev: uks
- github_environment: BLG2CODEDEV
- layer_sp_mode: create
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID
- existing_layer_sp_client_id_secret_name: EXISTING_LAYER_SP_CLIENT_ID
- existing_layer_sp_object_id_secret_name: EXISTING_LAYER_SP_OBJECT_ID

## Architecture summary

- Secure medallion architecture with layer isolation across identity, storage, and compute.
- Azure Databricks + Unity Catalog + Lakeflow jobs with orchestrator pattern.
- Azure Key Vault-backed runtime secret access pattern.
- Article leaves many concrete implementation values unstated; captured in SPEC and TODO.

## Generated artifacts

- SPEC.md
- README.md
- TODO.md
- .github/workflows/validate-terraform.yml
- .github/workflows/deploy-infrastructure.yml
- .github/workflows/deploy-dab.yml
- infra/terraform/versions.tf
- infra/terraform/providers.tf
- infra/terraform/variables.tf
- infra/terraform/locals.tf
- infra/terraform/main.tf
- infra/terraform/outputs.tf
- databricks-bundle/databricks.yml
- databricks-bundle/resources/jobs.yml
- databricks-bundle/src/setup/main.py
- databricks-bundle/src/bronze/main.py
- databricks-bundle/src/silver/main.py
- databricks-bundle/src/gold/main.py
- databricks-bundle/src/smoke_test/main.py

## Validation results

- Python compile: PASS
  - Generator scripts under `.github/skills/blog-to-databricks-iac/scripts/**/*.py`
  - Bundle entrypoints under `databricks-bundle/src/**/main.py`
- Terraform init/validate: PASS
  - `terraform -chdir=infra/terraform init -backend=false -input=false`
  - `terraform -chdir=infra/terraform validate`
- YAML parse: PASS
  - `.github/workflows/*.yml`
  - `databricks-bundle/**/*.yml`
- Generator runtime (re-run): PASS
  - validate/deploy/deploy-dab/jobs generators all executed successfully
- `jobs.yml` regeneration hash parity: PASS
- Workflow parity script: PASS
  - required `TF_VAR_*` parity
  - `-input=false` on all apply invocations
- Invariants: PASS
  - `databricks_workspace_url` and `databricks_workspace_resource_id` outputs present
  - Key Vault `recover_soft_deleted_key_vaults` is variable-driven
  - no `data "azuread_*"` blocks in Terraform
  - `databricks.yml` includes `resources/*.yml`
  - all `spark_python_task.python_file` paths are `../`-relative
  - TODO required sections present; no unresolved placeholders or HTML comments
  - SPEC not-stated coverage index in TODO is >= SPEC count

## Deferred items summary

- Pre-deployment: RBAC, Entra permissions for create mode, GitHub environment, source system/format definition, metastore attachment, naming confirmation
- Deployment-time inputs: recovery mode, state strategy, dispatch combination, schedule/trigger decisions
- Post-infrastructure: AKV-backed scope, runtime secrets, UC grants, setup logic, layer logic
- Post-DAB: orchestrator run, isolation verification, monitoring baseline
- Architectural deferred: remote backend, shared-key hardening, cluster policies, networking posture, rotation policy, UC system tables, fmt gate

Deferred-item source of truth: TODO.md

# Execution Record

## Scope

Regenerated the blog-derived Azure Databricks implementation after a full reset of generated artifacts.

## Defaults Used

- workload: `blg`
- environment: `dev`
- azure_region: `uksouth`
- github_environment: `BLG2CODEDEV`
- layer_sp_mode: `existing`
- Azure secret names: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SP_OBJECT_ID`
- Existing layer principal secret names: `EXISTING_LAYER_SP_CLIENT_ID`, `EXISTING_LAYER_SP_OBJECT_ID`

## Artifacts Regenerated

- `SPEC.md`
- `infra/terraform/versions.tf`
- `infra/terraform/providers.tf`
- `infra/terraform/variables.tf`
- `infra/terraform/locals.tf`
- `infra/terraform/main.tf`
- `infra/terraform/outputs.tf`
- `.github/workflows/validate-terraform.yml`
- `.github/workflows/deploy-infrastructure.yml`
- `.github/workflows/deploy-dab.yml`
- `databricks-bundle/databricks.yml`
- `databricks-bundle/resources/jobs.yml`
- `databricks-bundle/src/setup/main.py`
- `databricks-bundle/src/bronze/main.py`
- `databricks-bundle/src/silver/main.py`
- `databricks-bundle/src/gold/main.py`
- `README.md`
- `TODO.md`

## Validation

- `terraform -chdir=infra/terraform init -backend=false` passed earlier in the run.
- `terraform -chdir=infra/terraform validate` passed earlier in the run.
- `python .github/skills/blog-to-databricks-iac/scripts/azure/generate_jobs_bundle.py --output databricks-bundle/resources/jobs.yml` passed.
- `python -m py_compile` passed for the DAB bridge, jobs generator, and restored bundle entrypoints.
- YAML parsing passed for:
  - `databricks-bundle/databricks.yml`
  - `databricks-bundle/resources/jobs.yml`
  - `.github/workflows/validate-terraform.yml`
  - `.github/workflows/deploy-infrastructure.yml`
  - `.github/workflows/deploy-dab.yml`

## Notes

- The bundle declares 14 variables, including `workspace_resource_id`, to stay aligned with the deploy bridge contract.
- Schema defaults were corrected to `ingestion`, `refined`, and `curated` to match Terraform locals and the intended catalog layout.
- Restoring the bundle entrypoints exposed duplicated stale content in the bronze, silver, and gold scripts; those files were replaced with clean single-copy versions before final validation.

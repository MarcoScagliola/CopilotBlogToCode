# Secure Medallion Architecture on Azure Databricks (Part I)

This repository contains generated infrastructure and Databricks bundle assets derived from:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Run context:
- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create
- github_environment: BLG2CODEDEV

## What gets deployed

- Terraform in `infra/terraform` for Azure resource group, storage accounts, Databricks workspace, access connectors, Key Vault, identities, and RBAC.
- Databricks Asset Bundle in `databricks-bundle` for setup/bronze/silver/gold/smoke-test jobs and orchestrator flow.
- GitHub workflows in `.github/workflows` for validation, infrastructure deploy, and DAB deploy.

## Required GitHub environment secrets

In environment `BLG2CODEDEV`:
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`

Optional when `layer_sp_mode=existing`:
- `EXISTING_LAYER_SP_CLIENT_ID`
- `EXISTING_LAYER_SP_OBJECT_ID`

## Generated outputs

- `SPEC.md` architecture extraction from the article.
- `TODO.md` unresolved decisions and operator tasks.
- Terraform outputs file generated at runtime as artifact: `terraform-outputs`.

## Validation commands

- `python -m py_compile .github/skills/blog-to-databricks-iac/scripts/azure/*.py`
- `find databricks-bundle/src -name 'main.py' -exec python -m py_compile {} +`
- `terraform -chdir=infra/terraform init -backend=false`
- `terraform -chdir=infra/terraform validate`
- `python -c "import yaml,glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('.github/workflows/*.yml')]"`
- `python -c "import yaml,glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('databricks-bundle/**/*.yml', recursive=True)]"`
- `bash .github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh`
- `bash .github/skills/blog-to-databricks-iac/scripts/validate_bundle_parity.sh`
- `bash .github/skills/blog-to-databricks-iac/scripts/validate_handler_coverage.sh`

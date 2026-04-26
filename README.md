# Secure Medallion Architecture on Azure Databricks

This repository implements the architecture described in:
- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

It deploys:
- Azure infrastructure with Terraform (`infra/terraform`)
- Databricks runtime assets with a Databricks Asset Bundle (`databricks-bundle`)
- CI/CD workflows for Terraform validation, infrastructure deployment, and DAB deployment (`.github/workflows`)

## Run Context Used
- workload: `etl`
- environment: `dev`
- azure_region: `uksouth`
- github_environment: `BLG2CODEDEV`
- layer_sp_mode: `existing`

## Prerequisites
- Terraform >= 1.6.0
- Python 3.10+
- Azure credentials available as GitHub secrets or environment variables
- Databricks CLI available in deployment workflow runtime

## Expected GitHub Secrets / Variables
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`
- `EXISTING_LAYER_SP_CLIENT_ID` (required when `layer_sp_mode=existing`)
- `EXISTING_LAYER_SP_OBJECT_ID` (required when `layer_sp_mode=existing`)

## Architecture Summary
- Per-layer storage accounts: Bronze, Silver, Gold.
- Per-layer Databricks Access Connectors.
- Layer identities can be created (`create`) or reused (`existing`).
- Orchestrator job runs Setup -> Bronze -> Silver -> Gold -> Smoke Test.
- Managed tables in Unity Catalog are used by the sample runtime implementation.

## Workflows
- `validate-terraform.yml`: Terraform init/validate checks.
- `deploy-infrastructure.yml`: Terraform apply and outputs artifact publication.
- `deploy-dab.yml`: Bundle deploy consuming terraform outputs and deploy context artifacts.

## Local Validation Commands
```powershell
python -m py_compile .github/skills/blog-to-databricks-iac/scripts/azure/generate_validate_workflow.py .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_workflow.py .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_dab_workflow.py .github/skills/blog-to-databricks-iac/scripts/azure/generate_jobs_bundle.py .github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py databricks-bundle/src/setup/main.py databricks-bundle/src/bronze/main.py databricks-bundle/src/silver/main.py databricks-bundle/src/gold/main.py databricks-bundle/src/smoke_test/main.py
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
"C:\Program Files\Git\bin\bash.exe" .github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh
```

## Smoke Test Job
The generated `smoke_test` job validates that these tables exist and have rows:
- Bronze: `raw_events`
- Silver: `events`
- Gold: `event_summary`

## Post-Deploy Checklist
Use:

```powershell
python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --contract-only
```

For unresolved items and manual setup, see `TODO.md`.

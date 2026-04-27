# Secure Medallion Architecture on Azure Databricks

This repository implements the architecture described in:
- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

It deploys:
- Azure infrastructure with Terraform (`infra/terraform`)
- Databricks runtime assets with a Databricks Asset Bundle (`databricks-bundle`)
- CI/CD workflows for Terraform validation, infrastructure deployment, and DAB deployment (`.github/workflows`)

## Run Context Used

- workload: `blg`
- environment: `dev`
- azure_region: `uksouth`
- github_environment: `BLG2CODEDEV`
- layer_sp_mode: `create` (or `existing` in restricted tenants)

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

Use Enterprise Application object IDs for all `*_OBJECT_ID` values.

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
Get-ChildItem .github/skills/blog-to-databricks-iac/scripts/azure -Filter *.py | ForEach-Object { python -m py_compile $_.FullName }
Get-ChildItem databricks-bundle/src -Recurse -Filter main.py | ForEach-Object { python -m py_compile $_.FullName }

terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate

python -c "import yaml, glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('.github/workflows/*.yml')]"
python -c "import yaml, glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('databricks-bundle/**/*.yml', recursive=True)]"

python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --contract-only
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

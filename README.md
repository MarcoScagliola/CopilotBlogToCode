# Secure Medallion Architecture on Azure Databricks

This repository implements the architecture from:
- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

The generated solution includes:
- Terraform infrastructure in `infra/terraform`
- Databricks Asset Bundle runtime assets in `databricks-bundle`
- GitHub Actions workflows in `.github/workflows`
- deployment documentation in `SPEC.md` and `TODO.md`

## Run Context Used

- workload: `blg`
- environment: `dev`
- azure_region: `uksouth`
- github_environment: `BLG2CODEDEV`
- layer_sp_mode: `create` by default, with `existing` supported

## Prerequisites

- Terraform 1.6 or newer
- Python 3.10 or newer
- A GitHub environment named `BLG2CODEDEV`
- Azure credentials available as GitHub secrets or environment variables
- Databricks CLI available in the deployment workflow runtime

## Required GitHub Secrets / Variables

- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`

When `layer_sp_mode=existing`, also provide:

- `EXISTING_LAYER_SP_CLIENT_ID`
- `EXISTING_LAYER_SP_OBJECT_ID`

Use Enterprise Application object IDs for all `*_OBJECT_ID` values, not App Registration object IDs.

## Architecture Summary

- Separate storage account per layer: Bronze, Silver, Gold.
- Separate Databricks access connector per layer.
- Separate layer principals when `layer_sp_mode=create`, or a reusable existing principal path when `layer_sp_mode=existing`.
- Orchestrator job runs Setup -> Bronze -> Silver -> Gold -> Smoke Test.
- Unity Catalog managed tables are used for runtime data objects.
- Runtime secrets are read from Azure Key Vault through a Databricks secret scope.

## Workflows

- `.github/workflows/validate-terraform.yml`: runs Terraform init and validate without a backend.
- `.github/workflows/deploy-infrastructure.yml`: applies Terraform, handles soft-deleted Key Vault recovery, and uploads output artifacts.
- `.github/workflows/deploy-dab.yml`: consumes Terraform outputs and deploys the Databricks Asset Bundle.

## Local Validation Commands

```powershell
python -m py_compile .github/skills/blog-to-databricks-iac/scripts/azure/*.py
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
python -c "import yaml, glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('.github/workflows/*.yml')]"
python -c "import yaml, glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('databricks-bundle/**/*.yml', recursive=True)]"
python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --contract-only
```

## Smoke Test Job

The generated `smoke_test_job` validates that the following managed tables exist and contain rows:

- Bronze: `raw_events`
- Silver: `events`
- Gold: `event_summary`

## After Infrastructure Deployment

Use `TODO.md` for the required post-infrastructure tasks:

- create the AKV-backed Databricks secret scope
- populate the runtime secret keys in Azure Key Vault
- grant Unity Catalog privileges to the layer principals and verify storage access
- run the orchestrator job end to end

## Documentation

- `SPEC.md` documents what was stated versus not stated in the source article.
- `TODO.md` captures the manual setup and unresolved decisions the blog leaves open.
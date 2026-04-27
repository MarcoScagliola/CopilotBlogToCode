# Secure Medallion Architecture on Azure Databricks

This repository implements the architecture described in:  
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Infrastructure is provisioned with Terraform. Databricks jobs are deployed with a Databricks Asset Bundle. CI/CD is split across three GitHub Actions workflows.

## Prerequisites

- Azure subscription with Contributor access for the deployment principal.
- Permissions in Microsoft Entra ID to create App Registrations and Service Principals (when using `layer_sp_mode=create`), or pre-created principals for `layer_sp_mode=existing`.
- GitHub Environment `BLG2CODEDEV` configured with the secrets/variables below.
- Terraform CLI >= 1.6 and Python 3.11+ for local validation.

## Required GitHub Secrets / Variables

### Always required

| Name | Description |
|---|---|
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_CLIENT_ID` | Deployment service principal client ID |
| `AZURE_CLIENT_SECRET` | Deployment service principal secret |
| `AZURE_SP_OBJECT_ID` | Deployment service principal **object ID** (Enterprise Applications → Object ID, not App Registration) |

### Conditional — required when `layer_sp_mode=existing`

| Name | Description |
|---|---|
| `EXISTING_LAYER_SP_CLIENT_ID` | Existing layer principal client ID |
| `EXISTING_LAYER_SP_OBJECT_ID` | Existing layer principal **object ID** (Enterprise Applications → Object ID) |

> **Important:** `*_SP_OBJECT_ID` values must be the **Service Principal object ID** from Microsoft Entra ID → Enterprise applications, not the App Registration object ID.

## One-Time Setup

1. Create or identify the deployment service principal in Entra ID.
2. Assign Azure RBAC:
   - `Contributor` on the target resource group or subscription.  
   - For `layer_sp_mode=create`: Request `Application.ReadWrite.All` in Entra ID (or pre-create principals and use `layer_sp_mode=existing`).
3. Retrieve the object ID: Azure Portal → Entra ID → Enterprise applications → your app → **Object ID**.
4. Populate GitHub Environment `BLG2CODEDEV` with all required secrets above.
5. Choose identity mode for layer principals (`create` or `existing`) and set the dispatch input accordingly.

## Run Context Used

- workload: `etl`
- environment: `dev`
- azure_region: `uksouth`
- github_environment: `BLG2CODEDEV`
- layer_sp_mode: `existing`

## Architecture Summary

- Per-layer storage accounts: Bronze, Silver, Gold.
- Per-layer Databricks Access Connectors for secure storage access.
- Layer identities can be created (`create`) or reused (`existing`).
- Orchestrator job runs Setup → Bronze → Silver → Gold → Smoke Test.
- Managed tables in Unity Catalog.

## Workflows

### Validate Terraform
- File: [.github/workflows/validate-terraform.yml](.github/workflows/validate-terraform.yml)
- Trigger: `workflow_dispatch`
- Runs `terraform init -backend=false` and `terraform validate`. No credentials required beyond tenant/subscription.

### Deploy Infrastructure
- File: [.github/workflows/deploy-infrastructure.yml](.github/workflows/deploy-infrastructure.yml)
- Trigger: `workflow_dispatch`
- Dispatch inputs: `target`, `workload`, `environment`, `azure_region`, `key_vault_recovery_mode`, `layer_sp_mode`, `state_strategy`.
- Dispatch options for `state_strategy`:
  - `fail` (default): stop if resources already exist and no state is available.
  - `recreate_rg`: delete `rg-etl-dev-platform` before apply for repeatable ephemeral runs.
- Runs `terraform apply`, uploads `terraform-outputs` and `deploy-context` artifacts for DAB handoff.

### Deploy DAB
- File: [.github/workflows/deploy-dab.yml](.github/workflows/deploy-dab.yml)
- Trigger: `workflow_dispatch` (requires `infra_run_id`) or automatic after successful infrastructure deployment.
- Downloads Terraform output artifacts and deploys the Databricks Asset Bundle.

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

## Documentation

- [SPEC.md](SPEC.md) — architecture decisions and asset inventory
- [TODO.md](TODO.md) — prerequisites, unresolved items, and post-deployment steps

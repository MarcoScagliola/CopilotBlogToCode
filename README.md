# Secure Medallion Architecture on Azure Databricks

This repository implements the secure medallion architecture pattern from the [Microsoft Tech Community blog post](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268). Each medallion layer (Bronze, Silver, Gold) runs as a dedicated Databricks Lakeflow job with its own service principal, isolated ADLS Gen2 storage, and least-privilege RBAC assignments. An orchestrator job chains the three layer jobs in sequence.

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

## Workflows

### Validate Terraform
- File: [.github/workflows/validate-terraform.yml](.github/workflows/validate-terraform.yml)
- Trigger: `workflow_dispatch`
- Runs `terraform init -backend=false` and `terraform validate`. No credentials required beyond tenant/subscription.

### Deploy Infrastructure
- File: [.github/workflows/deploy-infrastructure.yml](.github/workflows/deploy-infrastructure.yml)
- Trigger: `workflow_dispatch`
- Dispatch inputs: `target`, `workload`, `environment`, `azure_region`, `layer_sp_mode`, `state_strategy`.
- `state_strategy` options:
  - `fail` (default): stop if resources already exist and no state is available.
  - `recreate_rg`: delete `rg-<workload>-<environment>-platform` before apply for repeatable ephemeral runs.
- Runs `terraform apply`, uploads `terraform-outputs` and `deploy-context` artifacts for DAB handoff.

### Deploy DAB
- File: [.github/workflows/deploy-dab.yml](.github/workflows/deploy-dab.yml)
- Trigger: `workflow_dispatch` (requires `infra_run_id`) or automatic after successful infrastructure deployment.
- Downloads Terraform output artifacts and deploys the Databricks Asset Bundle.

## Documentation

- [SPEC.md](SPEC.md) — architecture decisions and output contract
- [TODO.md](TODO.md) — prerequisites and unresolved items

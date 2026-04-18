# Secure Medallion Architecture on Azure Databricks

This repository implements a secure medallion pattern inspired by the referenced Microsoft blog. The deployment uses isolated bronze/silver/gold storage and job layers, service-principal-based identity boundaries, and a split CI/CD model where infrastructure and Databricks bundle deployment are decoupled.

The architecture emphasizes least privilege and clear separation of duties across storage, identity, and compute orchestration.

## Prerequisites

- Azure subscription with permissions to create resource groups, storage accounts, key vaults, and Azure Databricks workspaces.
- Service principal credentials available in GitHub Environment `BLG2CODEDEV`.
- Permissions in Microsoft Entra ID to create applications/service principals when using `layer_sp_mode=create`.
- Terraform CLI and Python 3.11+ for local validation.

## Required GitHub Secrets/Variables

Always required:

| Name | Purpose |
|---|---|
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_CLIENT_ID` | Deployment service principal client ID |
| `AZURE_CLIENT_SECRET` | Deployment service principal secret |
| `AZURE_SP_OBJECT_ID` | Deployment service principal object ID (Enterprise Applications object ID) |

Conditional for `layer_sp_mode=existing`:

| Name | Purpose |
|---|---|
| `EXISTING_LAYER_SP_CLIENT_ID` | Reused layer principal client ID |
| `EXISTING_LAYER_SP_OBJECT_ID` | Reused layer principal object ID (Enterprise Applications object ID) |

Architecture-specific runtime secrets:

- Source-system credentials should be stored in Azure Key Vault and read at runtime from Databricks, not passed as workflow parameters.

## One-Time Setup

1. Register or identify the deployment service principal in Microsoft Entra ID.
2. Assign least-privilege Azure RBAC required for Terraform deployment scope.
3. Populate the GitHub Environment `BLG2CODEDEV` secrets/variables listed above.
4. Decide identity mode for layer principals:
	 - `create`: Terraform creates bronze/silver/gold principals.
	 - `existing`: provide existing layer principal client/object IDs.

## Workflows

### Validate Terraform
- Workflow: `.github/workflows/validate-terraform.yml`
- Trigger: manual `workflow_dispatch`
- Purpose: run `terraform init -backend=false` and `terraform validate`

### Deploy Infrastructure
- Workflow: `.github/workflows/deploy-infrastructure.yml`
- Trigger: manual `workflow_dispatch`
- Purpose: apply Terraform and upload `terraform-outputs` plus `deploy-context` artifacts

### Deploy DAB
- Workflow: `.github/workflows/deploy-dab.yml`
- Trigger:
	- Manual `workflow_dispatch` (requires `infra_run_id`)
	- Automatic `workflow_run` after successful infrastructure deployment
- Purpose: deploy Databricks Asset Bundle with Terraform output handoff

## Documentation

- [SPEC.md](SPEC.md)
- [TODO.md](TODO.md)


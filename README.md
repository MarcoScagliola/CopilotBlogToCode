# Secure Medallion Architecture on Azure Databricks

This repository implements the architecture from:

- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

The implementation enforces least privilege by isolating Bronze, Silver, and Gold across identity, storage, and compute. Infrastructure is provisioned with Terraform and Databricks jobs are deployed using a Databricks Asset Bundle (DAB).

## What Is Implemented

- Three ADLS Gen2 storage accounts (one per layer)
- Three layer identities (create mode) or one reusable existing identity (existing mode)
- Per-layer RBAC to storage accounts
- Databricks workspace (Premium SKU)
- Three Databricks Access Connectors (one per layer)
- Azure Key Vault for runtime secret storage
- DAB with Bronze, Silver, Gold, and orchestrator jobs
- GitHub Actions workflows for validation, infra deploy, and DAB deploy

## Prerequisites

- Azure subscription
- Deployment service principal with:
  - Contributor on subscription or target resource group
  - User Access Administrator on subscription when Terraform must create RBAC assignments
  - Application.ReadWrite.All in Entra ID only if using `layer_sp_mode=create`
- GitHub Environment `BLG2CODEDEV` with required secrets/variables
- Python 3.11+
- Terraform CLI 1.6+

## Required GitHub Secrets or Variables

Always required:

- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`

Conditional (`layer_sp_mode=existing`):

- `EXISTING_LAYER_SP_CLIENT_ID`
- `EXISTING_LAYER_SP_OBJECT_ID`

Important:

- `AZURE_SP_OBJECT_ID` and `EXISTING_LAYER_SP_OBJECT_ID` must be Service Principal object IDs from Entra ID Enterprise Applications.
- Do not use App Registration object IDs for RBAC assignments.

## Workflows

1. `Validate Terraform` (`.github/workflows/validate-terraform.yml`)
	- Runs `terraform init -backend=false` and `terraform validate`

2. `Deploy Infrastructure` (`.github/workflows/deploy-infrastructure.yml`)
	- Dispatch inputs include `target`, `workload`, `environment`, `azure_region`, `layer_sp_mode`, and `state_strategy`
	- Publishes `terraform-outputs` and `deploy-context` artifacts

3. `Deploy DAB` (`.github/workflows/deploy-dab.yml`)
	- Consumes `terraform-outputs` and `deploy-context`
	- Uses Azure AD auth for Databricks CLI (no PAT required)

## Local Validation Commands

```bash
python -m py_compile \
  .github/skills/blog-to-databricks-iac/scripts/fetch_blog.py \
  .github/skills/blog-to-databricks-iac/scripts/reset_generated.py \
  .github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py \
  .github/skills/blog-to-databricks-iac/scripts/azure/generate_validate_workflow.py \
  .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_workflow.py \
  .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_dab_workflow.py \
  databricks-bundle/src/bronze/main.py \
  databricks-bundle/src/silver/main.py \
  databricks-bundle/src/gold/main.py

terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
```

## Post-Deployment Tasks

- Create Unity Catalog catalogs: `dev_bronze`, `dev_silver`, `dev_gold`
- Create schemas: `ingestion`, `refined`, `curated`
- Configure external locations and storage credentials in Unity Catalog
- Create Key Vault-backed secret scope: `kv-dev-scope`
- Grant Databricks privileges per layer principal
- Run `medallion-orchestrator-dev`

## Notes

- This repository uses ephemeral state by default in CI; for production, add a remote backend in `infra/terraform/backend.tf`.
- In restricted tenants where app registration creation is blocked, use `layer_sp_mode=existing`.

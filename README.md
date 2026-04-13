# Secure Medallion Architecture on Azure Databricks

This repository implements the Secure Medallion pattern from the referenced blog using Terraform plus Databricks Asset Bundles. Bronze, Silver, and Gold are isolated by storage, identity, and job execution context. Azure Key Vault backed Databricks secret scopes are used so JDBC credentials are only read at runtime.

## Architecture Overview
The solution deploys a security-first medallion architecture where each layer has dedicated storage, a dedicated Microsoft Entra service principal, and dedicated Databricks job definitions. Unity Catalog objects (catalogs, schemas, storage credentials, external locations, and grants) enforce layer boundaries and least privilege. An orchestrator job chains the three layer jobs for deterministic promotion from Bronze to Silver to Gold.

See [SPEC.md](SPEC.md) for the full architecture contract and [TODO.md](TODO.md) for unresolved values.

## Run Context
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID

## Prerequisites
- Azure subscription and tenant with permissions to create resource groups, Databricks workspace, storage, role assignments, and Key Vault.
- Databricks account with an existing Unity Catalog metastore ID.
- Deployment service principal credentials for Terraform and Databricks provider auth.
- GitHub repository with workflows enabled.

## Required GitHub Secrets
Always required:

| Scope | Secret Name | Purpose |
|---|---|---|
| GitHub Environment BLG2CODEDEV | AZURE_TENANT_ID | Terraform variable azure_tenant_id |
| GitHub Environment BLG2CODEDEV | AZURE_SUBSCRIPTION_ID | Terraform variable azure_subscription_id |
| Repository | AZURE_CLIENT_ID | SP client ID used by Terraform/Databricks auth |
| Repository | AZURE_CLIENT_SECRET | SP client secret used by Terraform/Databricks auth |
| Repository | DATABRICKS_ACCOUNT_ID | Databricks account identifier |
| Repository | DATABRICKS_METASTORE_ID | Unity Catalog metastore ID |

Architecture-specific:

| Scope | Secret Name | Purpose |
|---|---|---|
| Repository or Environment | JDBC_HOST | Source JDBC host |
| Repository or Environment | JDBC_DATABASE | Source JDBC database |
| Repository or Environment | JDBC_USER | Source JDBC username |
| Repository or Environment | JDBC_PASSWORD | Source JDBC password |

## One-Time Setup
1. Create or identify the deployment service principal and grant required Azure RBAC permissions.
2. Configure GitHub Environment BLG2CODEDEV with AZURE_TENANT_ID and AZURE_SUBSCRIPTION_ID.
3. Set repository secrets AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID, and DATABRICKS_METASTORE_ID.
4. Ensure the Databricks metastore exists and can be assigned to the new workspace.

## Workflows
Validate Terraform workflow:
1. Open GitHub Actions.
2. Run Validate Terraform.
3. Review format, init, and validate results for infra/terraform.

Deploy Infrastructure and DAB workflow:
1. Open GitHub Actions.
2. Run Deploy Infrastructure and DAB.
3. The workflow applies Terraform, reads outputs (including databricks_workspace_resource_id and databricks_workspace_url), and deploys the Databricks bundle.

## Local Usage (Optional)
Terraform:
1. Create infra/terraform/terraform.tfvars with secure values.
2. Run terraform init, terraform plan, and terraform apply from infra/terraform.

Databricks bundle:
1. Populate bundle variables from Terraform outputs.
2. Run databricks bundle validate in databricks-bundle.
3. Run databricks bundle deploy --target dev.

## File Map
- Terraform: [infra/terraform](infra/terraform)
- Databricks bundle: [databricks-bundle](databricks-bundle)
- Specification: [SPEC.md](SPEC.md)
- Unresolved values: [TODO.md](TODO.md)

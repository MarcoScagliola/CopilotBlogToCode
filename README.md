
# Secure Medallion Architecture On Azure Databricks

This repository implements the secure medallion pattern from the Azure Databricks blog post using Terraform for Azure and Unity Catalog infrastructure, and a Databricks Asset Bundle for Lakeflow Jobs and Python entrypoints. Bronze, Silver, and Gold are isolated by storage, identity, and compute so each layer can run with tightly scoped permissions and independent operational controls.

## Architecture Overview

The generated baseline provisions one Azure Databricks workspace, one Key Vault, and three storage-backed medallion layers. Terraform owns the Azure, Entra, access connector, and Unity Catalog setup; the Databricks Asset Bundle owns the Bronze, Silver, Gold, and orchestrator jobs.

## Prerequisites

- An Azure Service Principal with permission to create resource groups, Databricks workspaces, storage accounts, access connectors, Key Vault resources, and role assignments in the target subscription.
- An existing Databricks account ID and an existing Unity Catalog metastore ID.
- A GitHub Environment named `BLG2CODEDEV` containing `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID`.
- Repository secrets for the service principal credentials used by GitHub Actions.
- A Databricks workspace admin or equivalent principal able to validate the workspace-level service principal and Unity Catalog configuration after deployment.

## Required GitHub Secrets

### Always required

| Scope | Secret | Purpose |
|---|---|---|
| GitHub Environment `BLG2CODEDEV` | `AZURE_TENANT_ID` | Azure tenant for Terraform and Databricks Azure auth |
| GitHub Environment `BLG2CODEDEV` | `AZURE_SUBSCRIPTION_ID` | Azure subscription for Terraform |
| Repository | `AZURE_CLIENT_ID` | Service principal client ID used by GitHub Actions |
| Repository | `AZURE_CLIENT_SECRET` | Service principal client secret used by GitHub Actions |
| Repository | `DATABRICKS_ACCOUNT_ID` | Databricks account identifier |
| Repository | `DATABRICKS_METASTORE_ID` | Unity Catalog metastore identifier |

### Architecture-specific

| Scope | Secret | Purpose |
|---|---|---|
| Repository | `JDBC_HOST` | Bronze source database host |
| Repository | `JDBC_DATABASE` | Bronze source database name |
| Repository | `JDBC_USER` | Bronze source database username |
| Repository | `JDBC_PASSWORD` | Bronze source database password |

## One-Time Setup

1. Register or identify the Azure Service Principal used by GitHub Actions and grant it the Azure roles needed to provision the target resource group, Databricks workspace, storage accounts, access connectors, Key Vault, and RBAC assignments.
2. Create the GitHub Environment `BLG2CODEDEV` and add `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID` there.
3. Add repository secrets `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `DATABRICKS_ACCOUNT_ID`, `DATABRICKS_METASTORE_ID`, `JDBC_HOST`, `JDBC_DATABASE`, `JDBC_USER`, and `JDBC_PASSWORD`.
4. After Terraform applies, create the Databricks secret scope named by the Terraform output `secret_scope_name` and back it with the generated Azure Key Vault.
5. Review workspace access, Unity Catalog grants, and cluster policies before promoting beyond development.

## Workflow Usage

### Validate Terraform

Run `.github/workflows/validate-terraform.yml` to execute `terraform init -backend=false` and `terraform validate` against `infra/terraform`.

### Deploy Infrastructure

Run `.github/workflows/deploy-infrastructure.yml` with:

- `target`: the DAB target to pair with the infrastructure run, usually `dev`
- `environment`: the environment value to pass to the bundle, usually `dev`

This workflow runs Terraform apply, exports `terraform-outputs.json`, and uploads a `deploy-context.json` artifact that records the target, environment, and commit SHA for the downstream bundle deployment.

### Deploy DAB

Run `.github/workflows/deploy-dab.yml` manually with the infrastructure workflow run ID, or let it trigger automatically from a successful infrastructure deployment. It downloads `terraform-outputs` and `deploy-context`, checks out the matching commit, and deploys the Databricks Asset Bundle using Azure service-principal authentication.

## Local Usage

### Terraform

```bash
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform plan
terraform -chdir=infra/terraform apply
```

### Databricks Asset Bundle

```bash
databricks bundle validate -t dev
databricks bundle deploy -t dev
databricks bundle run medallion_orchestrator -t dev
```

## Repo References

- [SPEC.md](SPEC.md)
- [TODO.md](TODO.md)

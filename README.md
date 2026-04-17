# Secure Medallion Architecture On Azure Databricks

This repository implements the secure medallion pattern from the Azure Databricks blog post using Terraform for Azure and Databricks-adjacent infrastructure, and a Databricks Asset Bundle for Lakeflow Jobs and Python entrypoints. Bronze, Silver, and Gold are isolated by storage, identity, and compute so each layer can run with tightly scoped permissions and independent operational controls.

## Architecture Overview

The generated baseline provisions one Azure Databricks workspace, one Key Vault, and three storage-backed medallion layers. Terraform owns Azure resources, Entra identity integration, access connectors, and Unity Catalog setup; the Databricks Asset Bundle owns the Bronze, Silver, Gold, and orchestrator jobs.

## Prerequisites

- An Azure Service Principal with permission to create resource groups, Databricks workspaces, storage accounts, access connectors, Key Vault resources, and role assignments in the target subscription.
- A GitHub Environment named `BLG2CODEDEV` containing the required Azure secrets.
- A Databricks administrator or equivalent principal able to validate Unity Catalog availability, workspace principals, and storage credential behavior after deployment.

## Required GitHub Secrets

### Always required

| Scope | Secret | Purpose |
|---|---|---|
| GitHub Environment `BLG2CODEDEV` | `AZURE_TENANT_ID` | Azure tenant for Terraform and Databricks Azure auth |
| GitHub Environment `BLG2CODEDEV` | `AZURE_SUBSCRIPTION_ID` | Azure subscription for Terraform |
| GitHub Environment `BLG2CODEDEV` | `AZURE_CLIENT_ID` | Service principal client ID used by GitHub Actions |
| GitHub Environment `BLG2CODEDEV` | `AZURE_CLIENT_SECRET` | Service principal client secret used by GitHub Actions |

### Compatibility and runtime secrets

| Scope | Secret | Purpose |
|---|---|---|
| GitHub Environment `BLG2CODEDEV` | `AZURE_SP_OBJECT_ID` | Existing service principal object ID used when `layer_sp_mode=existing` |
| Azure Key Vault | `jdbc-host` | Bronze source database host |
| Azure Key Vault | `jdbc-database` | Bronze source database name |
| Azure Key Vault | `jdbc-user` | Bronze source database username |
| Azure Key Vault | `jdbc-password` | Bronze source database password |

## One-Time Setup

1. Register or identify the Azure Service Principal used by GitHub Actions and grant it the Azure roles needed to provision the target resource group, Databricks workspace, storage accounts, access connectors, Key Vault, and RBAC assignments.
2. Create the GitHub Environment `BLG2CODEDEV` and add `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, and `AZURE_CLIENT_SECRET`.
3. If the tenant blocks Entra app creation, also add `AZURE_SP_OBJECT_ID` and use the `existing` layer service principal mode in the infrastructure workflow.
4. After Terraform applies, confirm the workspace is Unity Catalog-enabled in your Databricks account posture.
5. Populate the generated Azure Key Vault with `jdbc-host`, `jdbc-database`, `jdbc-user`, and `jdbc-password`, then create the Databricks secret scope named by Terraform output `secret_scope_name` and back it with that Key Vault.
6. Review workspace access, Unity Catalog behavior, and cluster defaults before promoting beyond development.

## Workflow Usage

### Validate Terraform

Run `.github/workflows/validate-terraform.yml` to execute `terraform init -backend=false` and `terraform validate` against `infra/terraform`.

### Deploy Infrastructure

Run `.github/workflows/deploy-infrastructure.yml` with:

- `target`: the DAB target to pair with the infrastructure run, usually `dev`
- `environment`: the environment value to pass to the bundle, usually `dev`
- `layer_sp_mode`: `create` for per-layer Entra identities, or `existing` to reuse one already-created identity in restricted tenants

This workflow runs Terraform apply, exports `terraform-outputs.json`, and uploads a `deploy-context.json` artifact that records the target, environment, and commit SHA for the downstream bundle deployment.

### Deploy DAB

Run `.github/workflows/deploy-dab.yml` manually with the infrastructure workflow run ID, or let it trigger after a successful infrastructure deployment. It downloads `terraform-outputs` and `deploy-context`, checks out the matching commit, and deploys the Databricks Asset Bundle using Azure service-principal authentication.

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

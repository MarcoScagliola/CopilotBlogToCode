# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

This repository implements the Azure Databricks architecture pattern described in [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268). The pattern, the design choices it captures, and the trade-offs it makes are documented in detail in [SPEC.md](SPEC.md). This README is the operator's runbook: it tells you what you need, how to set it up, and how to deploy.

## What this repository deploys

A security-first Medallion Architecture on Azure Databricks with strict per-layer isolation:

- Three ADLS Gen2 storage accounts, one each for Bronze, Silver, and Gold.
- Three Azure Databricks Access Connectors (system-assigned managed identities), one per layer.
- One Azure Databricks Premium workspace with Secure Cluster Connectivity (No Public IP).
- One Azure Key Vault for runtime secrets, intended to be exposed to Databricks through an AKV-backed secret scope.
- Three per-layer service principals (create mode) used by jobs, each with narrowly scoped RBAC.
- Four Databricks jobs (setup, bronze, silver, gold) plus one orchestrator flow in the bundle.

Infrastructure is provisioned with Terraform under [infra/terraform/](infra/terraform/). Databricks workloads are deployed via a Databricks Asset Bundle under [databricks-bundle/](databricks-bundle/). CI/CD is split across three GitHub Actions workflows, each with a single responsibility.

For anything the source article did not specify and which the operator must decide, see [TODO.md](TODO.md). The TODO list is structured by deployment phase and must be worked through sequentially.

## Repository layout

```
.
├── infra/terraform/              Platform layer (resource group, storage, identity, Key Vault, workspace)
├── databricks-bundle/            Workload layer (jobs, entry points, environment configuration)
│   ├── databricks.yml
│   ├── resources/
│   └── src/
├── .github/workflows/            CI/CD pipelines (validate, deploy infra, deploy bundle)
├── SPEC.md                       Architecture decisions read from the source article
├── TODO.md                       Operator checklist for everything the article left unstated
└── README.md                     This file
```

## Prerequisites

### Azure environment

- An Azure subscription where the deployment principal has at minimum `Contributor` and `User Access Administrator` at subscription scope.
- Target region support for all services in this architecture (`uksouth` by default).
- If a soft-deleted Key Vault with the same target name exists, use workflow input `key_vault_recovery_mode=auto` (default).

### Microsoft Entra ID (identity)

The deployment principal needs the following identities provisioned before workflows run:

- A deployment service principal used by GitHub Actions (tenant ID, subscription ID, client ID, client secret, service-principal object ID).
- For `layer_sp_mode=create` (this run), the deployment principal must have Entra directory permissions to create app registrations and service principals (for example `Application.ReadWrite.All`, tenant policy permitting).
- For `layer_sp_mode=existing` (alternative mode), pre-create layer principals and set `EXISTING_LAYER_SP_CLIENT_ID` + `EXISTING_LAYER_SP_OBJECT_ID` secrets.

## Required GitHub secrets and variables

All credentials live in GitHub Environment `BLG2CODEDEV`.

### Always required

| Name | Type | Description |
|---|---|---|
| `AZURE_TENANT_ID` | Secret or variable | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Secret or variable | Azure subscription ID |
| `AZURE_CLIENT_ID` | Secret or variable | Deployment principal application (client) ID |
| `AZURE_CLIENT_SECRET` | Secret or variable | Deployment principal client secret |
| `AZURE_SP_OBJECT_ID` | Secret or variable | Deployment principal enterprise application object ID |

### Conditional (only for `layer_sp_mode=existing`)

| Name | Type | Description |
|---|---|---|
| `EXISTING_LAYER_SP_CLIENT_ID` | Secret or variable | Existing layer principal client ID |
| `EXISTING_LAYER_SP_OBJECT_ID` | Secret or variable | Existing layer principal enterprise application object ID |

Important: object ID values must come from Microsoft Entra ID Enterprise Applications, not App Registrations.

## Workflows

### Validate Terraform

- File: [.github/workflows/validate-terraform.yml](.github/workflows/validate-terraform.yml)
- Trigger: `workflow_dispatch`
- Purpose: syntax/configuration validation (`terraform init -backend=false`, `terraform validate`)

### Deploy Infrastructure

- File: [.github/workflows/deploy-infrastructure.yml](.github/workflows/deploy-infrastructure.yml)
- Trigger: `workflow_dispatch`
- Purpose: provision Azure resources and upload `terraform-outputs` + `deploy-context` artifacts

Inputs:
- `target`: DAB target (`dev` or `prd`)
- `workload`: defaults to `blg`
- `environment`: defaults to `dev`
- `azure_region`: defaults to `uksouth`
- `key_vault_recovery_mode`: `auto` | `recover` | `fresh`
- `layer_sp_mode`: `create` | `existing`
- `state_strategy`: `fail` | `recreate_rg`

### Deploy DAB

- File: [.github/workflows/deploy-dab.yml](.github/workflows/deploy-dab.yml)
- Trigger: workflow dispatch or chained from successful infra deployment
- Purpose: download `terraform-outputs` + `deploy-context`, checkout matching commit SHA, deploy Databricks bundle

## State strategy and recovery

- `state_strategy=fail` (default): safe mode for preserving resources and avoiding destructive resets.
- `state_strategy=recreate_rg`: destructive dev-mode reset; deletes target resource group then recreates resources.
- `key_vault_recovery_mode=auto` (default): recovery-first strategy for soft-deleted Key Vault handling.

## Post-deployment

Before end-to-end runs succeed, complete TODO items:

1. Create AKV-backed Databricks secret scope (`kv-dev-scope`).
2. Populate Key Vault with runtime secret values expected by entrypoints.
3. Establish Unity Catalog grants for layer principals and validate Access Connector RBAC.
4. Run smoke-test and orchestrator jobs.
5. Configure schedules and cluster policies as required.

## Troubleshooting

- `Authorization_RequestDenied` during apply:
  deployment principal lacks Entra app-registration permission while using `layer_sp_mode=create`.
- `PrincipalNotFound` in role assignments:
  object ID likely taken from App Registration instead of Enterprise Application.
- Key Vault conflict errors on reruns:
  use `key_vault_recovery_mode=auto` and avoid `fresh` when soft-deleted vault exists.

## Documentation index

- [SPEC.md](SPEC.md) — architecture checklist mapped from source article
- [TODO.md](TODO.md) — unresolved and post-deploy actions
- [.github/skills/blog-to-databricks-iac/REPO_CONTEXT.md](.github/skills/blog-to-databricks-iac/REPO_CONTEXT.md) — repo-specific defaults and contracts
- [.github/skills/blog-to-databricks-iac/SKILL.md](.github/skills/blog-to-databricks-iac/SKILL.md) — orchestrator instructions

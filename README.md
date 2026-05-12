# Secure Medallion Architecture Pattern on Azure Databricks

This repository implements the Azure Databricks architecture pattern described in [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268). The pattern, the design choices it captures, and the trade-offs it makes are documented in detail in [SPEC.md](SPEC.md). This README is the operator's runbook: it tells you what you need, how to set it up, and how to deploy.

## What this repository deploys

A security-first Medallion architecture that enforces least-privilege isolation across Bronze, Silver, and Gold data layers. Each layer runs under its own Microsoft Entra ID service principal with tightly scoped access: a dedicated ADLS Gen2 storage account, a Databricks Access Connector with system-assigned managed identity, and a Unity Catalog External Location. Three Lakeflow jobs handle ingestion, transformation, and curation respectively; a fourth orchestrator job sequences them. A single Azure Key Vault per environment backs a Databricks secret scope used by all layer jobs at runtime.

Infrastructure is provisioned with Terraform under [`infra/terraform/`](infra/terraform/). Databricks workloads (jobs, entry points, environment configuration) are deployed via a Databricks Asset Bundle under [`databricks-bundle/`](databricks-bundle/). CI/CD is split across three GitHub Actions workflows, each with a single responsibility.

For anything the source article did not specify and which the operator must decide, see [TODO.md](TODO.md). The TODO list is structured by deployment phase and must be worked through sequentially.

## Repository layout

```
.
├── infra/terraform/              Platform layer (resource group, storage, identity, Key Vault, workspace, access connectors)
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

- An Azure subscription where the deployment principal has at minimum `Contributor` and `User Access Administrator` on the target subscription (or resource group if pre-created). `User Access Administrator` is required to create role assignments for the Access Connector SAMIs and layer service principals.
- The target region (`uksouth` by default for this repository, overridable at dispatch time) must support all services: ADLS Gen2, Azure Key Vault, Azure Databricks Premium, and Databricks Access Connectors.
- If your tenant has a soft-deleted Key Vault from a previous deployment in this region with the same name, the deploy workflow will detect it and recover it. No manual cleanup is required. See *State strategy and recovery* below.

### Microsoft Entra ID (identity)

The deployment principal needs the following identities provisioned **before** the workflows can run:

- **A deployment Service Principal.** This is the identity GitHub Actions uses to authenticate to Azure. It needs its tenant ID, subscription ID, client ID, client secret, and Service Principal object ID (the object ID from *Enterprise Applications*, not from *App Registrations* — these are two different objects with two different IDs).
- **Optionally, one layer principal for all Databricks data layers** when running with `layer_sp_mode=existing`. When running with `layer_sp_mode=create`, the workflow creates separate per-layer principals on your behalf using the deployment SP's Entra permissions.

This repository is designed to work in **restricted tenants**, meaning tenants where the deployment principal cannot read Microsoft Graph. All object IDs are passed in as secrets, never resolved from names at plan time.

### Local tooling (optional, for validation)

- Terraform CLI `>= 1.6`
- Python `>= 3.11`
- Databricks CLI `>= 0.220` (only needed if you want to run bundle commands locally)

You do not need any of these installed to run the deployment, which is workflow-driven.

## Required GitHub Secrets and Variables

All secrets and variables live in the GitHub Environment named `BLG2CODEDEV`. The environment must be created before the workflows can dispatch.

### Always required

| Name | Type | Description |
|---|---|---|
| `AZURE_TENANT_ID` | Secret | Azure tenant ID (UUID) |
| `AZURE_SUBSCRIPTION_ID` | Secret | Azure subscription ID (UUID) |
| `AZURE_CLIENT_ID` | Secret | Deployment Service Principal **application (client) ID** |
| `AZURE_CLIENT_SECRET` | Secret | Deployment Service Principal client secret |
| `AZURE_SP_OBJECT_ID` | Secret | Deployment Service Principal **object ID** from *Enterprise Applications* |

### Conditional — required only when `layer_sp_mode=existing`

| Name | Type | Description |
|---|---|---|
| `EXISTING_LAYER_SP_CLIENT_ID` | Secret | Layer Service Principal client ID |
| `EXISTING_LAYER_SP_OBJECT_ID` | Secret | Layer Service Principal object ID from *Enterprise Applications* |

> **Important:** the two `*_OBJECT_ID` values must be the **Service Principal** object ID, which lives at *Microsoft Entra ID → Enterprise applications → your app → Object ID*. This is **not** the same as the *App Registration* object ID.

## One-time setup

### Step 1: Create or identify the deployment Service Principal

In the Azure portal: *Microsoft Entra ID → App registrations → New registration*. Give it a name that identifies its purpose (for example, `gh-actions-blg`). Once created, note down:
- The **Application (client) ID** from the App registration overview.
- A **client secret** from *Certificates & secrets*. Set an expiry that matches your team's rotation policy.
- The **Service Principal object ID** from *Microsoft Entra ID → Enterprise applications → your app → Object ID*.

### Step 2: Assign Azure RBAC

The deployment Service Principal needs:
- **`Contributor`** on the subscription or pre-existing resource group.
- **`User Access Administrator`** on the same scope — required to create role assignments for Access Connectors and layer service principals.

### Step 3: Decide on identity mode

Choose between:

- `layer_sp_mode=create` — the workflow creates a fresh Service Principal per data layer. The deployment principal needs `Application.ReadWrite.All` in Entra ID to do this.
- `layer_sp_mode=existing` — the workflow reuses a single Service Principal you have already created. You must provide its client ID and object ID as secrets.

If you are unsure, `existing` is the safer default. It works in any tenant, restricted or not.

### Step 4: Populate the GitHub Environment

In the GitHub repository: *Settings → Environments → New environment* (or select the existing one named `BLG2CODEDEV`). Add every secret listed in the *Always required* table above, plus the *Conditional* secrets if you chose `layer_sp_mode=existing`.

### Step 5: Review TODO.md

[TODO.md](TODO.md) lists every decision the source article did not make for you, plus the universal post-deploy actions. Read the *Pre-deployment* section before the first dispatch.

## Workflows

### Validate Terraform

| | |
|---|---|
| File | [`.github/workflows/validate-terraform.yml`](.github/workflows/validate-terraform.yml) |
| Trigger | `workflow_dispatch` |
| Auth required | Tenant + subscription IDs only |
| Outputs | None |

Runs `terraform init -backend=false` and `terraform validate`. Syntax and configuration check; does not touch Azure.

### Deploy Infrastructure

| | |
|---|---|
| File | [`.github/workflows/deploy-infrastructure.yml`](.github/workflows/deploy-infrastructure.yml) |
| Trigger | `workflow_dispatch` |
| Auth required | All *Always required* secrets, plus conditional ones |
| Outputs | `terraform-outputs` artifact, `deploy-context` artifact |

Dispatch inputs:

| Input | Type | Description |
|---|---|---|
| `target` | choice | Target Azure region. Defaults to `uksouth`. |
| `workload` | string | Workload identifier. Defaults to `blg`. |
| `environment` | choice | `dev` or `prd`. |
| `layer_sp_mode` | choice | `create` or `existing`. |
| `key_vault_recovery_mode` | choice | `auto`, `recover`, or `fresh`. |
| `state_strategy` | choice | `fail` (default) or `recreate_rg`. |

### Deploy DAB

| | |
|---|---|
| File | [`.github/workflows/deploy-dab.yml`](.github/workflows/deploy-dab.yml) |
| Trigger | `workflow_dispatch` (requires `infra_run_id`) or automatic on successful infrastructure deployment |
| Auth required | All *Always required* secrets |
| Outputs | None |

Downloads Terraform artifacts from the infrastructure run and deploys the Databricks Asset Bundle.

## State strategy and recovery

### `key_vault_recovery_mode`

| Value | Behaviour |
|---|---|
| `auto` (recommended) | The workflow detects whether a soft-deleted vault exists and recovers it. Handles three cases: in-place recovery, RG recreation then recovery, and legacy-RG detection. |
| `recover` | Force recovery. Fails if no soft-deleted vault exists. |
| `fresh` | Skip recovery and create a new vault. Fails if a soft-deleted vault with the same name exists. |

### `state_strategy`

| Value | Behaviour |
|---|---|
| `fail` (default) | Stop the workflow if Terraform detects pre-existing resources it does not own. Safe default for production. |
| `recreate_rg` | Delete the target resource group before applying. Useful for ephemeral dev environments. **Destructive — do not use in production.** |

## Post-deployment verification

After both workflows complete successfully:

1. **Populate Key Vault secrets.** Terraform creates the vault; you must add secret values manually. See [TODO.md](TODO.md).
2. **Verify external locations and storage credentials.** Unity Catalog external locations are created by the setup job. Verify them at *Catalog → External Data → External Locations*.
3. **Verify Unity Catalog grants.** Check that layer principals have the correct grants on their catalogs.
4. **Run the smoke test.** Trigger the `smoke_test` job from the Databricks workflows UI.
5. **Configure job schedules.** Jobs are deployed paused by default. Enable schedules from the UI once ready.

## Troubleshooting

| Symptom | Likely cause | Where to look |
|---|---|---|
| Role assignment fails with `PrincipalNotFound` | Object ID is for App Registration, not Service Principal | Re-fetch from *Enterprise Applications*, not *App Registrations*. |
| Deploy succeeds but bundle deploy fails on auth | DAB CLI env vars not aligned | Check `ARM_*` and `DATABRICKS_AZURE_RESOURCE_ID` in the deploy-dab workflow. |
| Key Vault create fails with `ConflictError: vault already exists` | Soft-deleted vault with same name in subscription | Set `key_vault_recovery_mode=auto` and re-dispatch. |
| `Authorization_RequestDenied` during `terraform apply` | Deployment SP lacks Entra `Application.ReadWrite.All` | Use `layer_sp_mode=existing` or grant directory permissions. |

## Documentation index

- [SPEC.md](SPEC.md) — every architectural decision read from the source article, plus inferred values and explicit gaps.
- [TODO.md](TODO.md) — the operator checklist, organised by deployment phase.
- [`.github/skills/blog-to-databricks-iac/SKILL.md`](.github/skills/blog-to-databricks-iac/SKILL.md) — the orchestrator skill that generated this repository.

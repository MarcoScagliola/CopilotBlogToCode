# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

This repository implements the Azure Databricks architecture pattern described in [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268). The pattern, the design choices it captures, and the trade-offs it makes are documented in detail in [SPEC.md](SPEC.md). This README is the operator's runbook: it tells you what you need, how to set it up, and how to deploy.

## What this repository deploys

- Secure medallion pattern with per-layer isolation across identity, storage, and compute.
- Azure Databricks jobs orchestrate Bronze, Silver, and Gold layer pipelines with a dedicated orchestrator job.
- Azure resources are provisioned by Terraform; Databricks runtime artifacts are deployed via DAB.

Infrastructure is provisioned with Terraform under [`infra/terraform/`](infra/terraform/). Databricks workloads (jobs, entry points, environment configuration) are deployed via a Databricks Asset Bundle under [`databricks-bundle/`](databricks-bundle/). CI/CD is split across three GitHub Actions workflows, each with a single responsibility.

For anything the source article did not specify and which the operator must decide, see [TODO.md](TODO.md). The TODO list is structured by deployment phase and must be worked through sequentially.

## Repository layout

```
.
├── infra/terraform/              Platform layer (networking, storage, identity, Key Vault, workspace)
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

- An Azure subscription where the deployment principal has at minimum `Contributor` on the target resource group, or on the subscription if the resource group does not yet exist.
- The target region (`uksouth` by default for this repository, overridable at dispatch time) must support all services this architecture uses. See [SPEC.md](SPEC.md) for the full service list.
- If your tenant has a soft-deleted Key Vault from a previous deployment in this region with the same name, the deploy workflow will detect it and recover it. No manual cleanup is required. See *State strategy and recovery* below.

### Microsoft Entra ID (identity)

The deployment principal needs the following identities provisioned **before** the workflows can run:

- **A deployment Service Principal.** This is the identity GitHub Actions uses to authenticate to Azure. It needs its tenant ID, subscription ID, client ID, client secret, and Service Principal object ID (the object ID from *Enterprise Applications*, not from *App Registrations* — these are two different objects with two different IDs).
- **Optionally, one layer principal per Databricks data layer** when running with `layer_sp_mode=existing`. The bundle uses these principals at runtime to access storage and Key Vault. When running with `layer_sp_mode=create`, the workflow creates them on your behalf and you do not need to provide them.

This repository is designed to work in **restricted tenants**, meaning tenants where the deployment principal cannot read Microsoft Graph. All object IDs are passed in as secrets, never resolved from names at plan time. If your tenant does allow Graph reads, the workflows still work — they just don't take advantage of that.

### Local tooling (optional, for validation)

- Terraform CLI `>= 1.6`
- Python `>= 3.11`
- Databricks CLI `>= 0.220` (only needed if you want to run bundle commands locally)

You do not need any of these installed to run the deployment, which is workflow-driven. They are useful if you want to validate changes before pushing.

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

> **Important:** the two `*_OBJECT_ID` values must be the **Service Principal** object ID, which lives at *Microsoft Entra ID → Enterprise applications → your app → Object ID*. This is **not** the same as the *App Registration* object ID. The two values look identical (both are UUIDs) but they refer to different objects, and role assignments against the wrong one will silently fail or, worse, succeed against the wrong principal. The naming convention `*_SP_OBJECT_ID` in this repository is a deliberate signpost.

## One-time setup

These steps need to be done once per target Azure subscription. After they are complete, every subsequent deployment is a workflow dispatch.

### Step 1: Create or identify the deployment Service Principal

In the Azure portal: *Microsoft Entra ID → App registrations → New registration*. Give it a name that identifies its purpose (for example, `gh-actions-blg`). You do not need to grant it any API permissions for this workflow to function — the Terraform skill does not read Microsoft Graph.

Once created, note down:
- The **Application (client) ID** from the App registration overview.
- A **client secret**, which you create under *Certificates & secrets*. Set an expiry that matches your team's rotation policy.
- The **Service Principal object ID**, which you find under *Microsoft Entra ID → Enterprise applications → your app → Object ID*. This is the one role assignments need.

### Step 2: Assign Azure RBAC

The deployment Service Principal needs Azure RBAC roles on the target scope. The minimum set is:

- **`Contributor`** on the subscription, or on the resource group if one already exists. This allows it to create and manage resources.
- **`User Access Administrator`** on the same scope. This allows it to create role assignments for the workspace and storage account, which the architecture requires.

If your security policy does not allow `User Access Administrator` on a Service Principal, you have two options. You can pre-create the role assignments manually and skip the relevant Terraform resources (the skill supports this via a flag in [SPEC.md](SPEC.md)). Or you can have a human approver run the relevant `az role assignment create` commands as a separate workflow step.

### Step 3: Decide on identity mode

Choose between:

- `layer_sp_mode=create` — the workflow creates a fresh Service Principal per data layer. The deployment principal needs `Application.ReadWrite.All` in Entra ID to do this.
- `layer_sp_mode=existing` — the workflow reuses one or more Service Principals you have already created. You must provide their client IDs and object IDs as secrets. The deployment principal needs no Entra permissions.

If you are unsure, `existing` is the safer default. It works in any tenant, restricted or not. `create` is useful in lab subscriptions where you want fully ephemeral identities.

### Step 4: Populate the GitHub Environment

In the GitHub repository: *Settings → Environments → New environment* (or select the existing one named `BLG2CODEDEV`). Add every secret listed in the *Always required* table above, plus the *Conditional* secrets if you chose `layer_sp_mode=existing`.

If you want to add a protection rule (required reviewers, deployment branch restrictions), this is the place to do it. The workflows respect environment protection.

### Step 5: Review TODO.md

[TODO.md](TODO.md) lists every decision the source article did not make for you, plus the universal post-deploy actions that apply to any Databricks workspace. You do not have to resolve everything in TODO.md before the first dispatch — many items are post-deployment — but you should at least read the *Pre-deployment* section so the workflow run does not stall on a missing input.

## Workflows

### Validate Terraform

| | |
|---|---|
| File | [`.github/workflows/validate-terraform.yml`](.github/workflows/validate-terraform.yml) |
| Trigger | `workflow_dispatch` |
| Auth required | Tenant + subscription IDs only (no SP credentials) |
| Outputs | None |

Runs `terraform init -backend=false` and `terraform validate`. This is a syntax and configuration check and does not touch Azure. Useful as a fast pre-flight before dispatching the deploy workflow, and as a CI gate on pull requests.

### Deploy Infrastructure

| | |
|---|---|
| File | [`.github/workflows/deploy-infrastructure.yml`](.github/workflows/deploy-infrastructure.yml) |
| Trigger | `workflow_dispatch` |
| Auth required | All *Always required* secrets, plus conditional ones based on dispatch inputs |
| Outputs | `terraform-outputs` artifact, `deploy-context` artifact (consumed by the DAB workflow) |

Dispatch inputs:

| Input | Type | Description |
|---|---|---|
| `target` | choice | Target Azure region. Defaults to `uksouth`. |
| `workload` | string | Workload identifier used in resource naming. Defaults to `blg`. |
| `environment` | choice | One of `dev`, `test`, `prod` (or whatever your repository defines). |
| `layer_sp_mode` | choice | `create` or `existing`. See *One-time setup, Step 3*. |
| `key_vault_recovery_mode` | choice | `auto`, `recover`, or `fresh`. See *State strategy and recovery* below. |
| `state_strategy` | choice | `fail` (default) or `recreate_rg`. See *State strategy and recovery* below. |

The workflow runs `terraform apply` against the target environment. On success, it uploads two artifacts that the DAB deployment workflow consumes:

- `terraform-outputs` — the JSON-formatted outputs from `terraform output -json`. The bundle reads workspace URL, storage account, and Key Vault references from here.
- `deploy-context` — a small metadata bundle including the commit SHA that was deployed. The DAB workflow uses this SHA when it checks out the repository, so that a manual DAB dispatch hours later still deploys against the exact code that produced the infrastructure.

### Deploy DAB

| | |
|---|---|
| File | [`.github/workflows/deploy-dab.yml`](.github/workflows/deploy-dab.yml) |
| Trigger | `workflow_dispatch` (requires `infra_run_id`) or automatic on successful infrastructure deployment |
| Auth required | All *Always required* secrets |
| Outputs | None |

This workflow takes the artifacts from a specific infrastructure run and deploys the Databricks Asset Bundle against them.

Dispatch inputs:

| Input | Type | Description |
|---|---|---|
| `infra_run_id` | string | The run ID of the infrastructure deployment whose outputs should be consumed. Required for manual dispatch. |
| `environment` | choice | Must match the environment the infrastructure was deployed to. |

The workflow downloads both artifacts, checks out the repository at the commit SHA recorded in `deploy-context`, then runs `databricks bundle deploy` with Terraform outputs mapped to bundle variables. It explicitly grants itself `actions: read` so that cross-run artifact downloads work without GitHub returning `Resource not accessible by integration`.

## State strategy and recovery

Azure has a few resources that do not behave well across repeated deploy/destroy cycles in the same subscription. Key Vault is the most prominent: by default, deleted vaults are *soft-deleted* and retained for 90 days. Attempting to create a vault with the same name in the same subscription during that window fails with a not-very-helpful error. This repository handles that case automatically.

### `key_vault_recovery_mode`

| Value | Behaviour |
|---|---|
| `auto` (recommended) | The workflow detects whether a soft-deleted vault exists and, if so, recovers it. If recovery puts it in the wrong resource group, the workflow moves it. Three branches are handled: in-place recovery, recovery plus move, and create-RG-then-recover. |
| `recover` | Force recovery. Fails if there is no soft-deleted vault to recover. Use this only when you know recovery is needed and you want the workflow to fail fast if the state has changed. |
| `fresh` | Skip recovery and create a new vault. Will fail if a soft-deleted vault with the same name exists. Use only when you have purged the prior vault out-of-band. |

### `state_strategy`

| Value | Behaviour |
|---|---|
| `fail` (default) | Stop the workflow if Terraform detects state mismatch or pre-existing resources it does not own. This is the safe default for production. |
| `recreate_rg` | Delete the target resource group before applying. Useful for ephemeral environments where you want a clean slate every run. Destructive — do not use in production. |

If you are running this workflow against a subscription that has been deployed into before, `key_vault_recovery_mode=auto` plus `state_strategy=fail` is almost always what you want. The recovery handler will deal with the vault, and any other state inconsistency will surface early.

## Post-deployment verification

After both workflows complete successfully, the infrastructure exists and the bundle is deployed, but the system is not yet "production-ready". There is a universal checklist of post-deploy actions for any Databricks-on-Azure deployment, regardless of architecture:

1. **Populate Key Vault secrets.** Terraform creates the vault and the access policies, but cannot create the secret values themselves (because secret values are not the kind of data Terraform should hold). See the *Post-infrastructure setup* section of [TODO.md](TODO.md) for the list of secret names this architecture expects.
2. **Verify external locations and storage credentials.** Unity Catalog external locations are created by the bundle's setup job. Verify they exist and are reachable from the workspace at *Catalog → External Data → External Locations*.
3. **Verify Unity Catalog grants.** The bundle creates the catalogs and schemas with the layer principals as owners. Verify the grants match what the source article describes for end-user and group access.
4. **Run the smoke test.** The bundle includes a `smoke_test` job that runs a minimal end-to-end check (read a sample, write to bronze, verify schema). Trigger it manually from the Databricks workflows UI. A successful run confirms identity, networking, and storage are all wired correctly.
5. **Configure job schedules.** The bundle deploys jobs in a paused state by default. Enable schedules from the Databricks workflows UI once you are ready for autonomous runs.

The [TODO.md](TODO.md) file walks through each of these in detail and tracks which ones are still outstanding.

## Troubleshooting

| Symptom | Likely cause | Where to look |
|---|---|---|
| `terraform plan` fails on `azuread_*` data source | A `data "azuread_*"` block leaked into the generated code | This should not happen. Open an issue against the orchestrator skill. The repository contract forbids Graph reads. |
| Role assignment fails with `PrincipalNotFound` | Object ID is for App Registration, not Service Principal | Re-fetch the object ID from *Enterprise Applications*, not from *App Registrations*. |
| Deploy succeeds but bundle deploy fails on auth | DAB CLI env vars not aligned with workflow secrets | Check that `ARM_*` and `DATABRICKS_AZURE_RESOURCE_ID` are exported explicitly in the deploy-dab workflow. |
| Workflow run hangs at `terraform plan` | A required variable was added to `variables.tf` without a matching `TF_VAR_*` in the workflow | Run [`scripts/validate_workflow_parity.sh`](scripts/validate_workflow_parity.sh) locally. It detects this case before the workflow runs. |
| Key Vault create fails with `ConflictError: vault already exists` | Soft-deleted vault with the same name in the subscription | Set `key_vault_recovery_mode=auto` and re-dispatch. |
| Recovered Key Vault is in a different resource group than expected | Vault was originally deployed under a different RG name | Set `key_vault_recovery_mode=auto` and re-dispatch — the recovery handler will move it. |

## Documentation index

- [SPEC.md](SPEC.md) — every architectural decision read from the source article, plus what was inferred from code snippets and what was explicitly *not stated*.
- [TODO.md](TODO.md) — the operator checklist, organised by deployment phase. Worked through sequentially.
- [`REPO_CONTEXT.md`](REPO_CONTEXT.md) — this repository's defaults (region, naming, environment names) for everything the source article does not specify.
- [`.github/skills/blog-to-databricks-iac/SKILL.md`](.github/skills/blog-to-databricks-iac/SKILL.md) — the orchestrator skill that generated this repository. Read this if you want to understand *how* the artifacts were produced, or if you want to regenerate them from a different source article.

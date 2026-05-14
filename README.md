# Secure Medallion Architecture on Azure Databricks (BLG DEV)

This repository implements a security-first medallion pattern inspired by the source article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

The baseline separates Bronze, Silver, and Gold with dedicated jobs, layer-level identity boundaries, separate storage accounts, and Key Vault-backed secret handling.

## What this repository deploys

- Azure infrastructure with Terraform in `infra/terraform/`.
- Databricks jobs and entrypoints via Databricks Asset Bundle in `databricks-bundle/`.
- CI/CD workflows in `.github/workflows/`:
	- `validate-terraform.yml`
	- `deploy-infrastructure.yml`
	- `deploy-dab.yml`

## Key inputs used for this generation

- `workload`: `blg`
- `environment`: `dev`
- `azure_region`: `uksouth`
- `layer_sp_mode`: `create`
- `github_environment`: `BLG2CODEDEV`

Default secret names used by generated workflows:
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`

## Repository layout

```text
.
|- infra/terraform/              Azure platform resources
|- databricks-bundle/            Databricks bundle resources and src
|- .github/workflows/            Validation and deployment workflows
|- SPEC.md                       Article-derived architecture summary
|- TODO.md                       Unresolved values and deferred decisions
|- README.md                     This runbook
```

## Prerequisites

- Azure subscription with required RBAC for the deployment principal.
- GitHub Environment `BLG2CODEDEV` with required secrets.
- Terraform CLI 1.6+ and Python 3.11+ for local validation.

## One-time setup

1. Create or choose the deployment service principal.
2. Assign required Azure RBAC roles.
3. Configure GitHub Environment secrets.
4. Review `TODO.md` and resolve pre-deployment entries.

## Workflow usage

1. Run `Validate Terraform` to validate static Terraform syntax.
2. Run `Deploy Infrastructure` with target inputs and recovery/state strategy.
3. Run `Deploy DAB` using the infrastructure run artifact handoff.

## Manual post-deploy actions

- Create Databricks secret scope backed by Azure Key Vault.
- Populate runtime secret keys in Key Vault.
- Apply Unity Catalog grants and validate principal isolation.
- Execute orchestrator and smoke-test jobs.

## Assumptions

- The article is architecture-oriented and leaves concrete source-system/runtime details unresolved.
- Defaults in generated code are baseline-safe and require environment-specific hardening.
- Non-destructive repeatable production operation should use remote Terraform state.

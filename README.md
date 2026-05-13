# Secure Medallion Architecture on Azure Databricks

This repository implements the Azure Databricks secure medallion pattern described in the source article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Generated deployment inputs:

- workload: blg
- environment: tst
- azure_region: uksouth
- layer_sp_mode: existing
- github_environment: BLG2CODEDEV

## What this repository deploys

- Terraform infrastructure in `infra/terraform`:
  - Resource group, key vault, Databricks workspace
  - Per-layer ADLS Gen2 storage accounts
  - Per-layer Databricks access connectors
  - Per-layer RBAC role assignments (no new service principals created; uses existing principal)
- Databricks Asset Bundle in `databricks-bundle`:
  - Setup, bronze, silver, gold, smoke-test, and orchestrator jobs
  - Python entrypoints for each job
  - Target definitions for dev and prd
- GitHub workflows in `.github/workflows`:
  - validate-terraform.yml
  - deploy-infrastructure.yml
  - deploy-dab.yml

See SPEC.md for article-to-architecture mapping and TODO.md for unresolved operational decisions.

## Prerequisites

- Azure subscription and tenant
- Deployment service principal with at least Contributor and User Access Administrator on target scope
- For layer_sp_mode=existing, an existing Entra service principal already created
- GitHub Environment BLG2CODEDEV with secrets:
  - AZURE_TENANT_ID
  - AZURE_SUBSCRIPTION_ID
  - AZURE_CLIENT_ID
  - AZURE_CLIENT_SECRET
  - AZURE_SP_OBJECT_ID
  - EXISTING_LAYER_SP_CLIENT_ID (the existing layer principal's client ID)
  - EXISTING_LAYER_SP_OBJECT_ID (the existing layer principal's object ID)

## Workflow usage

1. Run Validate Terraform (validate-terraform.yml) to verify Terraform syntax and contracts.
2. Run Deploy Infrastructure (deploy-infrastructure.yml) with desired target, key_vault_recovery_mode, and state_strategy.
3. Run Deploy DAB (deploy-dab.yml) manually with infra_run_id or let it trigger from successful infrastructure deployment.

## Notes

- This baseline favors deployability and then hardening; review TODO.md for post-deploy hardening items.
- The source article is architecture-focused; workload-specific source contracts and transformations must be finalized separately.
- In existing mode, no new service principals are created. All layers use the same existing principal referenced in EXISTING_LAYER_SP_*.

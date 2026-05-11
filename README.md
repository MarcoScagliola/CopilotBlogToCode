# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

This repository implements the architecture described in the source article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Run inputs used for this generation:
- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create

## What is generated

- Terraform infrastructure in `infra/terraform/`
- Databricks Asset Bundle in `databricks-bundle/`
- CI workflows in `.github/workflows/`
- Architecture and operator docs in `SPEC.md` and `TODO.md`

## Key architecture choices

- Medallion layout with Bronze, Silver, Gold isolation.
- Separate per-layer identities and storage accounts.
- Azure Key Vault-backed secret scope for runtime secret reads.
- Unity Catalog for governance and object isolation.
- Orchestrator job chaining setup -> bronze -> silver -> gold -> smoke test.

## Workflows

- `.github/workflows/validate-terraform.yml`
  - Terraform syntax and validation checks.
- `.github/workflows/deploy-infrastructure.yml`
  - Provisions Azure resources and publishes Terraform outputs.
- `.github/workflows/deploy-dab.yml`
  - Deploys Databricks bundle using infrastructure outputs.

## Required GitHub environment

GitHub Environment: `BLG2CODEDEV`

Required secrets:
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`

Conditional secrets when `layer_sp_mode=existing`:
- `EXISTING_LAYER_SP_CLIENT_ID`
- `EXISTING_LAYER_SP_OBJECT_ID`

## Validation checklist

- Python compile checks for scripts and entrypoints.
- Terraform init/validate with backend disabled.
- YAML parse for workflows and bundle YAML files.
- Generator reproducibility checks.
- Workflow parity check: `.github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh`
- Bundle parity check: `.github/skills/blog-to-databricks-iac/scripts/validate_bundle_parity.sh`

## Notes

- `TODO.md` tracks all unresolved and post-deploy work from article gaps.
- `SPEC.md` records what is stated vs not stated in article.

# Secure Medallion Architecture on Azure Databricks

This repository contains generated infrastructure and workload artifacts based on:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Run inputs used for this generation:

- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create
- github_environment: BLG2CODEDEV

## What is generated

- Terraform infrastructure under infra/terraform
- Databricks Asset Bundle under databricks-bundle
- GitHub Actions workflows under .github/workflows
- Architecture analysis in SPEC.md
- Operator checklist in TODO.md

## Workflows

- validate-terraform.yml: static Terraform validation.
- deploy-infrastructure.yml: provisions Azure resources and publishes Terraform outputs.
- deploy-dab.yml: deploys the Databricks Asset Bundle using infrastructure outputs.

All workflows target GitHub Environment BLG2CODEDEV and resolve credentials from secrets first, then environment variables.

## Required GitHub Environment Secrets

- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET
- AZURE_SP_OBJECT_ID

Since this run uses layer_sp_mode=create, existing layer principal secrets are not required.

## Terraform naming convention

Canonical naming pattern:

- rg-<workload>-<environment>-<region-abbr> (example: rg-blg-dev-uks)
- kv-<workload>-<environment>-<region-abbr> (example: kv-blg-dev-uks)
- dbw-<workload>-<environment>-<region-abbr> (example: dbw-blg-dev-uks)
- st<workload><environment><layer><region-abbr> (example: stblgdevbronzeuks)

For uksouth, region abbreviation is uks.

## Deployment sequence

1. Review and complete unresolved items in TODO.md.
2. Run Validate Terraform workflow.
3. Run Deploy Infrastructure workflow with appropriate input strategy.
4. Run Deploy DAB workflow using the infrastructure run id, or let it run from successful infra workflow completion.
5. Trigger Databricks orchestrator job and confirm bronze/silver/gold flow.

## Validation commands (local)

- python -m py_compile .github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py databricks-bundle/src/*/main.py
- terraform -chdir=infra/terraform init -backend=false
- terraform -chdir=infra/terraform validate
- bash .github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh
- bash .github/skills/blog-to-databricks-iac/scripts/validate_bundle_parity.sh
- bash .github/skills/blog-to-databricks-iac/scripts/validate_handler_coverage.sh

If bash is unavailable on Windows, use PowerShell or Python equivalents.

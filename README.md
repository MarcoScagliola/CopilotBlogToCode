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

- rg-workload-environment-regionabbr (example: rg-blg-dev-uks)
- kv-workload-environment-regionabbr (example: kv-blg-dev-uks)
- dbw-workload-environment-regionabbr (example: dbw-blg-dev-uks)
- stworkloadenvironmentlayerregionabbr (example: stblgdevbronzeuks)

For uksouth, region abbreviation is uks.

## Deployment sequence

1. Review and complete unresolved items in TODO.md.
2. Run Validate Terraform workflow.
3. Run Deploy Infrastructure workflow with appropriate input strategy.
4. Run Deploy DAB workflow using the infrastructure run id, or let it run from successful infra workflow completion.
5. Trigger Databricks orchestrator job and confirm bronze, silver, and gold flow.

## Validation commands (local)

- python -c "import py_compile,glob; [py_compile.compile(f, doraise=True) for f in glob.glob('.github/skills/blog-to-databricks-iac/scripts/azure/*.py') + ['databricks-bundle/src/setup/main.py','databricks-bundle/src/bronze/main.py','databricks-bundle/src/silver/main.py','databricks-bundle/src/gold/main.py','databricks-bundle/src/smoke_test/main.py']]"
- terraform -chdir=infra/terraform init -backend=false
- terraform -chdir=infra/terraform validate
- python -c "import yaml,glob; [yaml.safe_load(open(f,encoding='utf-8')) for f in glob.glob('.github/workflows/*.yml')]; print('workflows yaml ok')"
- python -c "import yaml,glob; [yaml.safe_load(open(f,encoding='utf-8',errors='ignore')) for f in glob.glob('databricks-bundle/**/*.yml', recursive=True)]; print('bundle yaml ok')"

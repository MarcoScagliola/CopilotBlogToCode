# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Run inputs:
- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create

## What This Repository Deploys

- Azure resource group and foundational platform resources
- Three ADLS Gen2 storage accounts (bronze/silver/gold)
- Three Databricks access connectors (SAMI), one per layer
- Azure Key Vault for runtime secret storage
- Azure Databricks Premium workspace with SCC/No Public IP
- Layer service principals (created when layer_sp_mode=create)
- Databricks bundle jobs and Python entrypoints

## Structure

- infra/terraform/: infrastructure code
- databricks-bundle/: DAB config, resources, and Python entrypoints
- .github/workflows/: generated validation/deployment workflows
- SPEC.md: article-derived architecture spec
- TODO.md: unresolved and deferred operator tasks

## Prerequisites

- Terraform >= 1.6
- Python >= 3.11
- Deployment principal with Contributor and User Access Administrator
- For create mode: Entra permission to create app registrations/service principals

## Required GitHub Environment

Environment: BLG2CODEDEV

Required secret/variable names:
- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET
- AZURE_SP_OBJECT_ID

## Workflows

- .github/workflows/validate-terraform.yml
- .github/workflows/deploy-infrastructure.yml
- .github/workflows/deploy-dab.yml

## Notes

- Object IDs must be Service Principal object IDs from Enterprise Applications.
- Credential resolution in workflows uses secrets.<NAME> || vars.<NAME>.
- See TODO.md for post-infrastructure and post-DAB actions.

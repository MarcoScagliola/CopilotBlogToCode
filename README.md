# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

This repository implements a security-first Azure Databricks medallion pattern derived from the Microsoft TechCommunity article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## What this repository deploys

- Azure infrastructure with Terraform in `infra/terraform/`:
	- Resource group, Azure Key Vault, three ADLS Gen2 storage accounts (bronze/silver/gold)
	- Azure Databricks workspace
	- Databricks access connectors with storage role assignments
- Databricks jobs and entrypoints with Asset Bundles in `databricks-bundle/`
- GitHub Actions workflows to validate Terraform, deploy infrastructure, and deploy DAB

Architecture details and blog-derived assumptions are in `SPEC.md`.
Operator actions that cannot be auto-generated are in `TODO.md`.

## Run profile for this generation

- Workload: `blg`
- Environment: `dev`
- Region: `uksouth`
- Layer SP mode: `create`
- GitHub environment: `BLG2CODEDEV`

## Quick flow

1. Configure required GitHub environment secrets in `BLG2CODEDEV`.
2. Run `Validate Terraform` workflow.
3. Run `Deploy Infrastructure` workflow.
4. Run `Deploy DAB` workflow.
5. Complete post-deploy actions from `TODO.md` (secret scope, runtime secrets, UC grants, functional run).

## Repository layout

- `infra/terraform/`: Azure infrastructure
- `databricks-bundle/`: Databricks Asset Bundle and Python entrypoints
- `.github/workflows/`: CI/CD workflows
- `SPEC.md`: article analysis and architecture contract
- `TODO.md`: deferred operator tasks and unresolved values

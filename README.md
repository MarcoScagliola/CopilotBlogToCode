# Secure Medallion Architecture Pattern on Azure Databricks

This repository implements the architecture from Secure Medallion Architecture Pattern on Azure Databricks (Part I):
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## What this deploys

- Terraform platform layer in infra/terraform:
	- Resource group in uksouth
	- Azure Databricks workspace
	- One ADLS Gen2 storage account per medallion layer (bronze, silver, gold)
	- One Databricks access connector per layer
	- Azure Key Vault for runtime secrets
- Databricks Asset Bundle in databricks-bundle:
	- Layer jobs (setup, bronze, silver, gold, smoke test)
	- One orchestrator job that runs layer jobs in order
- GitHub workflows:
	- validate-terraform.yml
	- deploy-infrastructure.yml
	- deploy-dab.yml

## Inputs used for this run

- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create
- github_environment: BLG2CODEDEV

## Prerequisites

- GitHub environment BLG2CODEDEV with:
	- AZURE_TENANT_ID
	- AZURE_SUBSCRIPTION_ID
	- AZURE_CLIENT_ID
	- AZURE_CLIENT_SECRET
	- AZURE_SP_OBJECT_ID
- Optional local tooling for validation:
	- Python 3.11+
	- Terraform 1.6+

## Deployment flow

1. Run Validate Terraform workflow.
2. Run Deploy Infrastructure workflow.
3. Run Deploy DAB workflow (auto after successful infrastructure run, or manual with infra_run_id).
4. Execute orchestrator and smoke test jobs in Databricks.

## Notes and assumptions

- Article-guided pattern values that were not explicitly stated are tracked in SPEC.md and TODO.md.
- This baseline is generated for first-run reproducibility and leaves remote Terraform backend setup as a deferred decision.
- Secrets are never stored in repository files and must be added in Azure Key Vault after infrastructure deployment.

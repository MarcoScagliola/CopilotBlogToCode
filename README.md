# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

This repository implements the architecture described in the source article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Run context used for this generation:

- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create

## What This Repository Deploys

- Azure Resource Group for workload resources
- Three ADLS Gen2 storage accounts (bronze/silver/gold)
- Three Databricks Access Connectors (system-assigned identity), one per layer
- One Azure Key Vault for runtime secret storage
- One Azure Databricks Premium workspace with Secure Cluster Connectivity (No Public IP)
- Three Entra app registrations + service principals (create mode)
- Databricks Asset Bundle with setup/bronze/silver/gold/smoke_test entrypoints and generated jobs

## Repository Layout

.
|- infra/terraform/                   Terraform infrastructure
|- databricks-bundle/                Databricks bundle and entrypoints
|- .github/workflows/                Generated CI workflows
|- SPEC.md                           Article analysis and assumptions
|- TODO.md                           Deferred items and operator actions
|- README.md                         This runbook

## Prerequisites

- Terraform >= 1.6
- Python >= 3.11
- Azure permissions for deployment principal:
	- Contributor
	- User Access Administrator
- For layer_sp_mode=create: Entra app registration permission (for example Application.ReadWrite.All)

## Required GitHub Environment And Secrets

Environment: BLG2CODEDEV

Required secret or variable names:

- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET
- AZURE_SP_OBJECT_ID

Notes:

- Object IDs must be Service Principal object IDs from Enterprise Applications.
- The generated workflows resolve credentials as secrets.<NAME> || vars.<NAME>.

## Workflows

- .github/workflows/validate-terraform.yml
	- Validates Terraform configuration only
- .github/workflows/deploy-infrastructure.yml
	- Applies Terraform and publishes terraform-outputs artifact
- .github/workflows/deploy-dab.yml
	- Deploys Databricks bundle from terraform outputs

## Runtime Inputs

Deploy infrastructure workflow dispatch inputs include:

- target
- workload
- environment
- azure_region
- key_vault_recovery_mode
- layer_sp_mode
- state_strategy

Recommended defaults for this run:

- target=dev
- workload=blg
- environment=dev
- azure_region=uksouth
- layer_sp_mode=create
- key_vault_recovery_mode=auto
- state_strategy=fail

## Post-Deploy Actions

See TODO.md for required operator actions, including:

- create AKV-backed Databricks secret scope
- populate runtime secrets in Key Vault
- configure Unity Catalog grants and ownership
- implement production Bronze/Silver/Gold transformations
- execute orchestrator and smoke tests end-to-end

## Troubleshooting

- If Terraform provider download fails during init with network timeouts, rerun init.
- If create mode fails with Authorization_RequestDenied, tenant policy is blocking app registration.
- If key vault conflicts appear on rerun, use key_vault_recovery_mode=auto.

## References

- SPEC.md
- TODO.md
- .github/skills/blog-to-databricks-iac/SKILL.md
- .github/skills/blog-to-databricks-iac/REPO_CONTEXT.md

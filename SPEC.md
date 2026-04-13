# Secure Medallion Architecture Spec

## Source
- Blog: Secure Medallion Architecture Pattern on Azure Databricks (Part I)
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Run Context
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID

## Architecture Summary
This implementation enforces a secure medallion data platform on Azure Databricks by isolating Bronze, Silver, and Gold layers across storage, identity, and compute. Each layer runs as a dedicated Microsoft Entra service principal with constrained Unity Catalog and storage permissions. Secrets are stored in Azure Key Vault and consumed at runtime through an AKV-backed Databricks secret scope.

## Terraform Scope
Terraform provisions:
- Azure resource group in uksouth.
- Three ADLS Gen2 storage accounts and private data containers (Bronze/Silver/Gold).
- Azure Key Vault and JDBC secrets.
- Per-layer Entra applications and service principals.
- Databricks access connectors (managed identity) per layer.
- Azure RBAC role assignments for least-privilege access.
- Azure Databricks workspace (Premium).
- Unity Catalog metastore assignment.
- Unity Catalog storage credentials, external locations, catalogs, schemas, and grants.
- AKV-backed Databricks secret scope.

## Databricks Asset Bundle Scope
The Databricks bundle provisions four jobs:
- Bronze ingestion job
- Silver transform job
- Gold publish job
- Orchestrator job chaining Bronze -> Silver -> Gold with post-run checkpoint

Each job is configured for variable-driven deployment and supports injected values for:
- workspace host
- per-layer catalog names
- per-layer service principal IDs
- secret scope name

## Naming Convention
All names are derived from workload/environment/region in locals:
- Resource group: rg-blg-dev-uks
- Workspace: dbw-blg-dev-uks
- Storage accounts: stblgbrzdev, stblgslvdev, stblgglddev
- Access connectors: dbac-blg-brz-dev-uks, dbac-blg-slv-dev-uks, dbac-blg-gld-dev-uks
- Catalogs: blg_brz_dev, blg_slv_dev, blg_gld_dev

## Required Terraform Outputs
Outputs required by workflows and DAB are included:
- databricks_workspace_resource_id
- databricks_workspace_url

# SPEC — Secure Medallion Architecture on Azure Databricks

## Source
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Summary
This implementation provisions a secure Bronze, Silver, Gold medallion data platform on Azure Databricks. Each layer is isolated by storage, compute, and identity, while an orchestrator job sequences the end-to-end flow. Terraform owns Azure and Databricks-adjacent infrastructure; the Databricks Asset Bundle owns the runtime jobs and Python entrypoints.

## Terraform Scope
Terraform provisions:
- resource group
- Azure Databricks workspace
- three ADLS Gen2 storage accounts and containers
- three Databricks Access Connectors with system-assigned managed identities
- Azure Key Vault with RBAC enabled
- per-layer Entra applications and service principals, or an existing shared identity in restricted tenants
- Unity Catalog storage credentials, external locations, catalogs, and schemas
- RBAC role assignments for storage and Key Vault access

## Databricks Bundle Scope
The Databricks Asset Bundle deploys:
- Bronze ingestion job
- Silver refinement job
- Gold aggregation job
- orchestrator job chaining Bronze → Silver → Gold

## Identity Model
Default mode creates one Entra application and service principal per medallion layer. For tenants that restrict Entra app creation, the deployment can run in `existing` mode and reuse a pre-created service principal.

## Storage and Security Notes
- one storage account per layer
- one access connector per layer
- storage accounts default to a deployment-compatible shared-key setting for AzureRM provider compatibility
- runtime access still uses managed identity and Databricks storage credentials
- secrets are retrieved at runtime through an AKV-backed Databricks secret scope

## Data Model
- Bronze writes raw inbound records to `blg_brz_dev.bronze_schema.inbound_events`
- Silver reads Bronze, deduplicates and refines, then writes to `blg_slv_dev.silver_schema.refined_events`
- Gold aggregates Silver into `blg_gld_dev.gold_schema.curated_daily_metrics`

## Workflow Model
- `validate-terraform.yml` validates Terraform syntax
- `deploy-infrastructure.yml` applies Terraform and exports outputs
- `deploy-dab.yml` reads Terraform outputs and deploys the bundle

# Architecture Specification

## Source
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Title: Secure Medallion Architecture Pattern on Azure Databricks (Part I)

## Summary
Implement a secure Medallion (Bronze/Silver/Gold) pattern on Azure Databricks using strict per-layer isolation for identities, storage, compute, and governance.

## Inferred Architecture
- Cloud: Azure only
- Databricks: 1 workspace, 3 layer jobs, 1 orchestrator job
- Storage: ADLS Gen2 with layer isolation (Bronze, Silver, Gold)
- Identity: Entra app/SP per layer, least privilege permissions
- Secrets: Azure Key Vault + Databricks secret scope
- Governance: Unity Catalog with per-layer catalogs/schemas, storage credentials, external locations

## Security Controls
- No shared identity across layers
- No shared cluster across layers
- Layer N can write only to its own layer
- Silver reads Bronze; Gold reads Silver
- Secrets read at runtime with `dbutils.secrets.get()`

## Explicit vs Assumed
Explicit in blog:
- Azure Databricks + Lakeflow jobs
- Per-layer service principals
- Per-layer storage and clusters
- Unity Catalog and Key Vault usage

Assumed for implementation:
- Managed tables in Unity Catalog
- Terraform manages Azure + UC infra
- DAB manages jobs and entrypoints
- Environment starts with `dev`

## Run Inputs Used
- `azure_region = uksouth`
- `workload = blg`
- `environment = dev`

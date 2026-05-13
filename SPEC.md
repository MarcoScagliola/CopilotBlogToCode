# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Scope
- Pattern: secure Medallion Architecture on Azure Databricks.
- Layers: Bronze, Silver, Gold.
- Security focus: least privilege, managed identities, Unity Catalog, Azure Key Vault, and isolated compute and storage per layer.

## Architecture Summary
- Azure Databricks is used to run layer-isolated Lakeflow jobs.
- Bronze ingests raw data, Silver refines it, and Gold publishes curated analytics-ready data.
- Unity Catalog governs tables, external locations, and access boundaries.
- Azure Key Vault stores runtime secrets and is exposed to Databricks through a Key Vault-backed secret scope.
- Each layer is isolated with its own identity, storage, and compute boundary.

## Inferred Components
- Inferred from article text:
  - Three layer-specific jobs.
  - Three dedicated clusters, one per layer.
  - Three layer-specific service principals.
  - Separate storage accounts per layer.
  - A Lakeflow orchestrator job that triggers the three layer jobs.

## Explicitly Not Stated in Article
- Exact runtime secret names and values.
- Exact source system connection details.
- Final enterprise RBAC matrix for human users.
- Production schedule cadence and operational SLAs.

## Decisions Applied in This Generation
- Workload code: blg
- Environment: dev
- Azure region: uksouth
- Layer principal mode: create
- GitHub environment: BLG2CODEDEV

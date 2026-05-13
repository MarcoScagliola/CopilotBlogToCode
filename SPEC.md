# Secure Medallion Architecture on Azure Databricks (Part I)

Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Scope
- Pattern: secure medallion architecture on Azure Databricks.
- Layers: Bronze, Silver, Gold.
- Security focus: identity-based access, Key Vault integration, and governed data access.

## Architecture Summary
- Azure Databricks workspace is the compute plane for batch data processing.
- Data is organized across medallion layers with progressive refinement from Bronze to Gold.
- Storage is separated by layer to support isolation and least privilege.
- Unity Catalog is used for governed table access and privilege boundaries.
- A Key Vault-backed secret model is used for runtime secret retrieval.

## Inferred Components
- Inferred from architecture pattern and examples in article:
  - One storage account per layer.
  - One access boundary per layer for storage access from Databricks.
  - Dedicated layer principals when stricter isolation is required.

## Explicitly Not Stated in Article
- Concrete production source system connection details.
- Exact runtime secret key names and values.
- Final enterprise RBAC matrix for all human groups.
- Production scheduling cadence and SLA windows.

## Decisions Applied in This Generation
- Workload code: blg
- Environment: dev
- Azure region: uksouth
- Layer principal mode: create
- GitHub environment: BLG2CODEDEV

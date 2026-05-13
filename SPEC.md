# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- High-level architecture pattern:
  - Secure Medallion architecture (bronze/silver/gold) with per-layer job and identity isolation.
  - Top-down implementation approach called out by the article.
- Named components and role each one plays:
  - Source systems and ingestion specifics: not stated in article.
  - Bronze, Silver, Gold layers: sequential processing and increasing data quality/business value.
  - Overarching orchestrator Lakeflow job: coordinates per-layer jobs.
  - BI consumer layer details: not stated in article.
- Data flow direction and triggers:
  - Multi-hop flow from bronze to silver to gold.
  - Trigger model or schedule details: not stated in article.
- Data volume, frequency, latency requirements:
  - not stated in article.

## Azure Services

- Azure Databricks, ADLS Gen2, Azure Key Vault, Microsoft Entra managed identities/service principals, Unity Catalog are referenced.
- Service SKUs/tier specifics for most services: not stated in article.
- Networking posture (private endpoints/firewalls/public network policy): not stated in article.
- Region and redundancy details: not stated in article.

## Databricks

- Workspace tier: not stated in article.
- Secure Cluster Connectivity/No Public IP setting: not stated in article.
- Unity Catalog usage: yes.
- Catalog separation for bronze/silver/gold is required by pattern; exact names not stated in article.
- Compute model uses dedicated clusters per layer.
- Jobs and orchestration use three layer jobs plus one orchestrator.
- Concurrency, scheduling, runtime/library specifics: not stated in article.

## Data Model

- Source systems and source formats: not stated in article.
- Layered target model (bronze/silver/gold) is stated.
- Exact table names and schemas: not stated in article.
- Partitioning/Liquid clustering/Z-ordering strategy: not stated in article.
- Explicit quality test thresholds/framework: not stated in article.

## Security And Identity

- Per-layer Entra service principals/managed identities are core to the pattern.
- Databricks Access Connector with system-assigned identity is highlighted.
- Secrets are stored in Azure Key Vault and consumed via AKV-backed Databricks secret scopes.
- Explicit RBAC matrix and detailed UC grant SQL: not stated in article.

## Operational Concerns

- Enable Key Vault diagnostic logs.
- Enable Databricks system tables and jobs monitoring UI for reliability and spend.
- CI/CD implementation is deferred to Part II.
- Backup/retention/DR details are not stated in article.

## Out-Of-Scope Markers

- Production CI/CD implementation and environment promotion details are deferred to Part II.
- Known challenges like cluster reusability are deferred to Part II.

## Other Observations

- Managed tables are recommended for the reference design.
- Managed-table storage paths are GUID-based and obfuscate physical table naming in storage.
- The article recommends one secret scope per environment with consistent key naming.

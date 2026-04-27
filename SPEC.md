# Architecture Specification - Secure Medallion Pattern (Part I)

Source article:
- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- High-level architecture pattern: secure medallion architecture with Bronze, Silver, and Gold data layers.
- Named components and roles:
  - Bronze Lakeflow job for ingestion.
  - Silver Lakeflow job for transformation.
  - Gold Lakeflow job for aggregation and serving.
  - Orchestrator Lakeflow job coordinating all layers.
- Data flow direction and triggers: layered sequential flow Bronze -> Silver -> Gold; schedule/trigger details are not stated in article.
- Stated or implied volume/frequency/latency requirements: not stated in article.

## Azure services

- Azure Databricks workspace for Lakeflow jobs and Unity Catalog governance.
- Azure Data Lake Storage Gen2 with separate storage accounts per layer.
- Azure Databricks Access Connector with system-assigned managed identities.
- Azure Key Vault for runtime secret storage and AKV-backed secret scopes.
- Microsoft Entra ID service principals for per-layer least-privilege execution.
- Networking posture: secure cluster connectivity (no public IP) is stated; broader networking specifics are not stated in article.
- Region/redundancy: not stated in article.

## Databricks

- Workspace tier: Premium inferred from UC and governance features; explicit tier not stated in article.
- Workspace type Hybrid: not stated in article.
- Secure Cluster Connectivity (No Public IP): stated.
- Unity Catalog usage: yes.
  - Separate catalogs for Bronze, Silver, and Gold are stated.
  - Schema names are not stated in article.
  - Metastore details are not stated in article.
- Compute model: dedicated per-layer clusters for layer jobs.
- Jobs and orchestration: one job per layer plus orchestrator.
- Lakeflow Spark Declarative Pipelines mode: not stated in article.
- Task source format/libraries/runtime/init scripts: not stated in article.

## Data model

- Source systems and formats: not stated in article.
- Target datasets grouped by layer: Bronze raw dataset, Silver refined dataset, Gold aggregated dataset.
- Partitioning/Z-order/liquid clustering strategy: not stated in article.
- Schema evolution/enforcement: not stated in article.
- Data quality rules: progressive quality intent is stated; concrete rules are not stated in article.

## Security and identity

- Identities used: per-layer Entra service principals and managed identities for access connectors.
- Secrets and storage: secrets in Azure Key Vault, read at runtime via AKV-backed Databricks secret scopes.
- RBAC assignments and UC grants: least-privilege model is stated; exact grant matrix is not stated in article.
- Network boundaries and paths: not stated in article.

## Operational concerns

- Monitoring/logging/alerting: Databricks Jobs monitoring UI, Databricks system tables, and AKV diagnostics are referenced.
- Cost controls: cluster isolation is stated; exact right-sizing/autoscaling controls are not stated in article.
- CI/CD approach in article: deferred to Part II.
- Backup/retention/disaster recovery: not stated in article.

## Out-of-scope markers

- CI/CD implementation details are deferred to Part II.
- Cluster reusability challenges are deferred.
- Environment promotion strategy is deferred.

## Other observations

- The architecture emphasizes least privilege across identity, storage, and compute boundaries.
- The article explicitly recommends managed tables under Unity Catalog for this pattern.
- Runtime secret retrieval with `dbutils.secrets.get(...)` is a non-negotiable pattern in this design.
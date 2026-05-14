# SPEC.md

## Source
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Title: Secure Medallion Architecture Pattern on Azure Databricks (Part I)
- Fetch date: 2026-05-14

## Architecture
- High-level architecture pattern: secure medallion architecture with Bronze, Silver, and Gold layers; each layer is isolated by identity, compute, and storage.
- Named components and roles: source systems feed Bronze ingestion; Silver standardizes and refines; Gold serves curated data for analytics consumers; orchestration is handled by Lakeflow Jobs.
- Data flow direction and triggers: sequential multi-hop pipeline Bronze -> Silver -> Gold, inferred from article narrative and architecture diagram; trigger cadence is presented as batch-style job orchestration.
- Stated or implied data volume/frequency/latency: not explicitly quantified in the article; implied operational model is scheduled, reliability-focused batch processing.

## Azure services
- Azure services named: Azure Databricks, ADLS Gen2 storage accounts, Azure Key Vault, Microsoft Entra ID managed identities/service principals, Unity Catalog, Azure Databricks Access Connector, and Lakeflow Jobs.
- Service roles and configuration:
  - Azure Databricks workspace hosts jobs, clusters, and Unity Catalog governance.
  - ADLS Gen2 provides layer-segregated storage.
  - Key Vault stores secrets consumed at runtime through Databricks secret scopes.
  - Entra ID service principals provide per-layer execution identities.
  - Access Connector ties managed identity-based access between Databricks and storage.
- Networking posture: the article emphasizes secure design and least privilege but does not provide a full private endpoint/firewall matrix; network hardening specifics are deferred.
- Region and redundancy: not stated in article.

## Databricks
- Workspace tier: not stated in article.
- Workspace type: Azure Databricks workspace, inferred as enterprise secure configuration.
- Secure cluster connectivity/no public IP: not explicitly stated as a mandatory deployment flag.
- Unity Catalog usage: yes. Catalog-per-layer isolation is explicitly recommended; schema names and metastore identifier are not explicitly named.
- Compute model: job clusters per layer, plus orchestration job, explicitly described.
- Jobs and orchestration: separate jobs for Bronze, Silver, Gold, plus one orchestrator that enforces dependency order.
- Lakeflow Spark Declarative Pipelines mode: Lakeflow Jobs are explicitly used; continuous vs triggered mode is not explicitly specified.
- Task source format: implementation examples in the article are conceptually notebook/job driven; this repo maps to Python entrypoints for deployability.
- Libraries/runtime/init scripts: not stated in article.

## Data model
- Source systems and formats: source systems are referenced conceptually; concrete source connector and wire format are not explicitly specified.
- Target datasets by layer:
  - Bronze: raw/landing-standardized ingestion tables.
  - Silver: cleaned, validated, and conformed datasets.
  - Gold: business-ready curated outputs for reporting/consumption.
- Partitioning or optimization strategy: the article discusses managed tables and governance; explicit liquid clustering or z-ordering prescription is not provided.
- Schema evolution/enforcement: data quality and progressive checks are emphasized conceptually; exact schema evolution policy is not detailed.
- Data quality expectations/tests: progressive quality checks and smoke-test style operational validation are implied.

## Security and identity
- Identities used: per-layer Entra ID service principals/managed identities; Databricks Access Connector identity for storage integrations.
- Secrets and storage location: secrets must be kept in Azure Key Vault and accessed from Databricks via AKV-backed secret scopes at runtime.
- RBAC and Unity Catalog grants: least-privilege RBAC and UC privilege segmentation are required conceptually; exact role assignment matrix is not exhaustively enumerated.
- Network boundaries and allowed paths: layer isolation and separation of duties are emphasized; detailed network path matrix is not provided.

## Operational concerns
- Monitoring/logging/alerting: enable system tables and use Jobs monitoring UI for failures, duration, and spend visibility.
- Cost controls: cluster separation and operational observability are discussed; concrete budget artifacts and reserved-capacity settings are not specified.
- CI/CD approach in article: article states CI/CD implementation will be detailed in Part II and is deferred.
- Backup/retention/disaster recovery: not stated in article.

## Out-of-scope markers
- CI/CD deployment implementation details are deferred to the next article in the series.
- Environment promotion and some operational challenges are acknowledged as future content.

## Other observations
- The architecture prioritizes blast-radius reduction by combining per-layer identity, storage, and compute isolation.
- Managed Unity Catalog tables are preferred in the article due to governance/abstraction benefits.
- Secret handling guidance is strict: no secrets in code, logs, or job parameters; runtime retrieval only.
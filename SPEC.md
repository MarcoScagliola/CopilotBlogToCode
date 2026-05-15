# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Fetch timestamp (UTC): 2026-05-15

## Architecture

- High-level pattern: Medallion Lakehouse (Bronze -> Silver -> Gold) with a fourth orchestrator job coordinating layer jobs.
- Named components and roles:
  - Azure Databricks workspace hosts Lakeflow jobs and Unity Catalog governance.
  - Three layer-scoped service principals execute jobs with least privilege.
  - Three storage accounts isolate Bronze, Silver, and Gold data paths.
  - Azure Key Vault stores runtime secrets.
  - Databricks secret scope (AKV-backed) provides runtime secret access from jobs.
- Data flow direction and trigger: sequential batch progression from Bronze to Silver to Gold, orchestrated by a top-level Lakeflow job.
- Data volume, frequency, latency: not stated in article.

## Azure services

- Azure Databricks: secure workspace for Lakeflow jobs and Unity Catalog.
- Azure Data Lake Storage Gen2: per-layer storage isolation (Bronze/Silver/Gold).
- Azure Databricks Access Connector: managed identity bridge for Unity Catalog data access.
- Azure Key Vault: secret store for runtime credentials.
- Microsoft Entra ID service principals: per-layer execution identities.
- Networking posture:
  - Secure Cluster Connectivity (No Public IP): explicitly recommended.
  - Private endpoints, VNet injection details, firewall rule specifics: not stated in article.
- Region and redundancy: not stated in article.

## Databricks

- Workspace tier: not stated in article.
- Workspace type: Azure Databricks workspace (hybrid details not stated in article).
- Unity Catalog usage: yes.
  - Separate catalogs per layer are recommended.
  - Schema naming specifics are not stated in article.
  - Metastore identifier is not stated in article.
- Compute model:
  - Three dedicated clusters, one per layer.
  - One setup job and one orchestrator job to coordinate execution.
  - Lakeflow jobs are used for orchestration and retries.
- Task source format: notebooks and Python are implied; this repository baseline uses Python file entrypoints.
- Runtime, libraries, init scripts: not stated in article.

## Data model

- Source systems and formats: not stated in article.
- Target datasets by layer:
  - Bronze: raw ingestion output.
  - Silver: cleaned/refined business model output.
  - Gold: curated analytics output.
- Partitioning strategy: not stated in article.
- Liquid clustering or Z-ordering strategy: not stated in article.
- Schema evolution rules: not stated in article.
- Data quality test rules: implied by progressive quality checks, but concrete rules are not stated in article.

## Security and identity

- Identities used:
  - Three layer service principals (Bronze/Silver/Gold).
  - Managed identities via Databricks Access Connectors.
- Secrets and storage:
  - Azure Key Vault stores secrets.
  - AKV-backed Databricks secret scopes expose runtime secrets.
- RBAC and grants:
  - Least-privilege per layer is explicit.
  - Exact Azure role assignments and Unity Catalog grant statements are not stated in article.
- Network boundaries: high-level isolation is explicit; concrete subnet/NSG/private endpoint topology is not stated in article.

## Operational concerns

- Monitoring and observability:
  - Jobs monitoring UI and system tables are explicitly recommended.
- Cost controls:
  - Cluster policies, autoscaling, and auto-termination are explicitly recommended.
  - Budget values or reserved-capacity commitments are not stated in article.
- CI/CD approach:
  - Article references CI/CD delivery in Part II; concrete pipeline implementation is out of scope in Part I.
- Backup, retention, DR specifics: not stated in article.

## Out-of-scope markers

- Detailed CI/CD implementation is deferred to Part II.
- Environment-promotion details are deferred to Part II.
- Cluster reusability specifics are deferred to Part II.

## Other observations

- The article favors managed tables under Unity Catalog for governance and simplified maintenance.
- It emphasizes complete separation of duties: identity, compute, and storage isolation per medallion layer.

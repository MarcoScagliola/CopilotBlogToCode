# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

- Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch timestamp (UTC): 2026-05-14T17:15:11Z
- Short summary: The article defines a security-first Medallion pattern on Azure Databricks with strict per-layer identity, storage, and compute isolation, plus an orchestrator job spanning Bronze, Silver, and Gold.

## Architecture

- High-level architecture pattern: Secure Medallion Architecture (Bronze, Silver, Gold) with an orchestrator Lakeflow (stated in article).
- Named components and role: ADLS Gen2 per layer, Azure Databricks Lakeflow Jobs, Unity Catalog, Azure Key Vault, Microsoft Entra service principals, Databricks Access Connectors (stated in article).
- Data flow direction and triggers: Bronze -> Silver -> Gold via separate layer jobs plus orchestrator; scheduling cadence is not stated in article.
- Data volume/frequency/latency requirements: not stated in article.

## Azure Services

- Azure Databricks: workspace hosting Lakeflow jobs and Unity Catalog (stated in article).
- Azure Data Lake Storage Gen2: separate storage accounts per Bronze, Silver, Gold (stated in article).
- Azure Key Vault: runtime secret store, referenced through AKV-backed Databricks secret scopes (stated in article).
- Microsoft Entra ID: service principals for each layer and deployment identities (stated in article).
- Azure Databricks Access Connector: system-assigned managed identity bridge for Unity Catalog storage access (stated in article).
- Log and cost observability references: Databricks system tables and Jobs monitoring UI; AKV diagnostic logs recommended (stated in article).
- For each service, explicit SKU/tier: not stated in article.
- Networking posture: no explicit private endpoint or VNet-injection implementation details for this baseline; checklist-targeted posture is inferred as no VNet injection for generated baseline.
- Region and redundancy strategy: not stated in article.

## Databricks

- Workspace tier: not stated in article.
- Workspace type: Hybrid (from checklist guidance for this run).
- Secure Cluster Connectivity (No Public IP): targeted as a security pattern in architecture intent, but exact workspace deployment flags are not stated in article.
- Unity Catalog usage: yes, with separate Bronze/Silver/Gold catalogs and schema-level isolation (stated in article).
- Metastore reference/name: not stated in article.
- Compute model: three dedicated clusters (one per layer) and one orchestrator Lakeflow (stated in article).
- Jobs and orchestration: three layer jobs plus one orchestrator job with dependencies (stated in article).
- Lakeflow mode (triggered vs continuous): not stated in article.
- Task source format: notebooks discussed in article; generated baseline uses Python files for deterministic CI generation (inferred from implementation choice).
- Libraries/runtime/init scripts: Databricks runtime variants and Photon guidance are discussed conceptually; exact runtime version and init scripts are not stated in article.

## Data Model

- Source systems and formats: source domains are discussed conceptually; concrete source systems/formats are not stated in article.
- Target datasets by layer: Bronze raw, Silver refined, Gold curated analytics-ready tables (stated in article).
- Partitioning/liquid clustering/z-ordering: managed-table optimization capabilities are discussed, but concrete per-table strategy is not stated in article.
- Schema evolution/enforcement: not stated in article.
- Data quality rules: progressive checks by layer are stated conceptually; specific test rules are not stated in article.

## Security And Identity

- Identities used: one Entra service principal per layer, plus Databricks Access Connector managed identities (stated in article).
- Secrets and location: API keys/passwords in Azure Key Vault, accessed via AKV-backed secret scopes at runtime (stated in article).
- RBAC and UC grants: least-privilege grants per layer and source/target read/write split are stated conceptually; exact role assignment matrix is not stated in article.
- Network boundaries and access paths: layer-level isolation objective is stated; detailed NSG/private-link topology is not stated in article.

## Operational Concerns

- Monitoring/logging/alerting: Databricks system tables, Jobs monitoring UI, and AKV diagnostics are explicitly recommended (stated in article).
- Cost controls: autoscaling, auto-termination, and cluster policy controls are stated conceptually (stated in article).
- CI/CD approach from article: explicitly deferred to Part II; this repository generates its own workflows (stated in article).
- Backup/retention/disaster recovery specifics: not stated in article.

## Out-Of-Scope Markers

- CI/CD implementation details and environment promotion mechanics are deferred to Part II (stated in article).
- Cluster reusability across Lakeflow jobs is called out as a follow-up challenge for Part II (stated in article).

## Other Observations

- The design emphasizes separation of duties as the core control: no single principal, cluster, or job can span all layers.
- Managed tables are the preferred pattern in the article due to governance and optimization behavior under Unity Catalog.
- This generated baseline preserves the security and orchestration intent while leaving explicitly unstated values in TODO.md for operator decisions.
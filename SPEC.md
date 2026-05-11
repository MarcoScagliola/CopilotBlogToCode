# SPEC — Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Run inputs:
- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create

## Architecture

- High-level architecture pattern:
  - Secure Medallion architecture (Bronze -> Silver -> Gold) with an orchestrator Lakeflow job driving per-layer jobs.
  - Least-privilege design is the central architectural goal (stated in prose).
- Named components and roles:
  - Source systems: not stated in article.
  - Bronze layer: raw ingestion and initial landing (stated in prose).
  - Silver layer: cleansed/integrated data (stated in prose).
  - Gold layer: curated/consumption-ready outputs (stated in prose).
  - Orchestrator Lakeflow job: sequences the three layer jobs (stated in prose).
  - BI consumers: implied but not explicitly named in article.
- Data flow direction and triggers:
  - Direction is Bronze -> Silver -> Gold (stated in prose).
  - Trigger model (scheduled vs event-driven vs on-demand) is not stated in article.
- Stated or implied data volume, frequency, latency:
  - Data volume is not stated in article.
  - Frequency is not stated in article.
  - Latency/SLA targets are not stated in article.

## Azure services

- Azure services named in the article and roles:
  - Azure Databricks: compute/orchestration platform for medallion jobs.
  - Azure Data Lake Storage Gen2 (ADLS Gen2): per-layer storage accounts for isolation.
  - Microsoft Entra ID service principals / managed identities: per-layer execution identities and auth.
  - Azure Databricks Access Connector: workspace-linked system-assigned managed identity for UC storage access.
  - Azure Key Vault (AKV): secret storage with runtime retrieval via Databricks secret scopes.
  - Unity Catalog: governance, catalogs/schemas/tables, external locations, system tables.
- Stated SKU/tier/configuration:
  - Databricks workspace tier is not stated in article.
  - Storage redundancy type (LRS/ZRS/GRS/RA-GRS) is not stated in article.
  - Key Vault SKU/tier is not stated in article.
- Networking posture:
  - Public endpoints / private endpoints / VNet injection / firewall posture are not stated in article.
- Region and redundancy:
  - Azure region is not stated in article.
  - Redundancy strategy is not stated in article.

## Databricks

- Workspace tier (Standard/Premium): not stated in article.
- Workspace type Hybrid: not stated in article.
- Deploy workspace with Secure Cluster Connectivity (No Public IP): not stated in article.
- Unity Catalog usage:
  - Unity Catalog usage: yes (stated in prose).
  - Separate catalogs for Bronze, Silver, Gold: yes (stated in prose).
  - Specific catalog names: not stated in article.
  - Schema names: not stated in article.
  - Metastore reference/name: not stated in article.
- Compute model:
  - Dedicated per-layer clusters (three clusters, one per layer) is stated in prose.
  - Cluster policy characteristics are discussed conceptually; concrete policy JSON/parameters are not stated in article.
  - Runtime version is not stated in article.
- Jobs and orchestration:
  - Three per-layer Lakeflow jobs plus one orchestrator job is stated in prose.
  - Job dependency chain exists (orchestrator drives layer jobs), inferred from architecture description.
  - Exact schedule/trigger/concurrency settings are not stated in article.
- Lakeflow Spark Declarative Pipelines usage and mode:
  - Lakeflow Jobs are used; Lakeflow Spark Declarative Pipelines mode (triggered/continuous) is not stated in article.
- Task source format:
  - Notebooks are referenced for runtime secret reads (`dbutils.secrets.get(...)`), inferred from code-style guidance.
  - Python files / SQL files / JAR / wheel usage is not stated in article.
- Libraries, runtime, init scripts:
  - Not stated in article.

## Data model

- Source systems and formats:
  - Source systems are not stated in article.
  - Data formats (CSV/JSON/Parquet/Avro/CDC/JDBC/REST) are not stated in article.
- Target tables/datasets by layer:
  - Layer intent is described (Bronze raw, Silver integrated, Gold serving).
  - Explicit table names and dataset inventory are not stated in article.
- Partitioning / Liquid Clustering / Z-order:
  - Partitioning guidance is not stated in article.
  - Liquid Clustering or Z-order usage is not stated in article.
- Schema evolution / enforcement:
  - Not stated in article.
- Data quality expectations / rules:
  - Progressive quality checks are mentioned conceptually.
  - Explicit quality gates/rules/thresholds are not stated in article.

## Security and identity

- Identities used:
  - Dedicated Microsoft Entra ID service principals per layer are stated in prose.
  - Managed identities are emphasized; Access Connector SAMI is stated in prose.
- Secrets and secret storage:
  - Store secrets in Azure Key Vault and read at runtime through AKV-backed Databricks secret scopes (stated in prose).
  - Example key names (`api-token`, `db-password`) are stated in prose.
- RBAC assignments and Unity Catalog grants:
  - Principle of least privilege and layer isolation are stated.
  - Exact RBAC role names and exact UC GRANT statements are not stated in article.
- Network boundaries:
  - Isolation requirement between layers is stated conceptually.
  - Explicit network topology and allowed paths are not stated in article.

## Operational concerns

- Monitoring, logging, alerting:
  - Enable Unity Catalog system tables and monitor Jobs UI (stated in prose).
  - Enable AKV diagnostic logs (stated in prose).
  - Exact alert rules/KPIs are not stated in article.
- Cost controls:
  - Track spend by layer via system tables / observability guidance.
  - Concrete cost guardrails (budgets, reserved capacity, spot policy, hard limits) are not stated in article.
- CI/CD or deployment approach in article:
  - Article says Part II will publish CI/CD code; concrete CI/CD implementation is deferred.
- Backup/retention/DR:
  - Not stated in article.

## Out-of-scope markers

- Article explicitly positions this as Part I and defers detailed CI/CD implementation to Part II.
- Some implementation specifics (for example, concrete cluster policy definitions) are high-level only and left for follow-up detail.

## Other observations

- Core security claim: compromise in one layer should not permit read/write access across other layers.
- Separation of duties is applied across identities, storage accounts, clusters, and jobs (multi-dimensional isolation).
- Managed tables are recommended; article notes GUID-based storage paths under Unity Catalog managed storage.

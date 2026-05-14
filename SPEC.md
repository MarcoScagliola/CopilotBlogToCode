# Secure Medallion Architecture Pattern on Azure Databricks (Part I) — SPEC

Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- High-level architecture pattern: medallion architecture (Bronze, Silver, Gold) with strict layer isolation.
- Named components and roles: source systems -> Bronze raw ingestion -> Silver refinement/transformation -> Gold curated analytics for BI/reporting/APIs.
- Data flow direction and triggers: sequential multi-hop Lakeflow jobs plus an orchestrator job; inferred from Lakeflow job guidance.
- Data volume, frequency, latency: not stated in article.

## Azure services

- Azure Databricks: workspace running Lakeflow jobs and Unity Catalog-governed data access.
- Azure Storage (ADLS Gen2): separate storage accounts per layer (bronze/silver/gold).
- Azure Key Vault: runtime secrets store for pipeline credentials, accessed from Databricks through AKV-backed secret scopes.
- Microsoft Entra ID managed service principals: per-layer non-human identities for least-privilege execution.
- Azure Databricks Access Connector: managed identity bridge for workspace/storage access under Unity Catalog.
- Networking posture: no public IP on clusters via secure cluster connectivity is stated; private endpoints/firewall specifics are not stated in article.
- Region and redundancy (LRS/ZRS/GRS): not stated in article.

## Databricks

- Workspace tier (Standard/Premium): not stated in article.
- Workspace type (hybrid context): inferred from Azure-native integration (Entra ID, ADLS, Key Vault, Access Connector).
- Secure Cluster Connectivity / No Public IP: explicitly required by the article's secure design guidance.
- Unity Catalog usage: yes; separate Bronze, Silver, Gold catalogs and external locations with storage credentials.
- Compute model: three dedicated layer clusters (one per layer) plus one orchestrator Lakeflow.
- Jobs and orchestration: one job per layer plus orchestrator, with layer-level isolation and dependency sequencing.
- Lakeflow mode (triggered vs continuous): inferred as triggered/scheduled job model from Lakeflow Jobs usage.
- Task source format (notebooks/python/sql/jar/wheel): notebooks are referenced; Python-file implementation detail is not stated in article.
- Libraries/runtime/init scripts: not stated in article.

## Data model

- Source systems and formats: not stated in article.
- Targets by layer:
  - Bronze: raw immutable Delta ingestion.
  - Silver: cleansed and integrated business-ready datasets.
  - Gold: curated analytics-ready datasets.
- Partitioning/liquid/z-order strategy: managed tables are preferred; automatic liquid clustering/predictive optimization are noted for managed tables.
- Schema evolution/enforcement rules: not stated in article.
- Data quality expectations: progressive quality checks per layer are stated; concrete test rules and thresholds are not stated in article.

## Security and identity

- Identities used: one Entra-managed service principal per layer, plus managed identities via Databricks Access Connectors.
- Secrets and storage: Azure Key Vault with one AKV-backed secret scope per environment in Databricks.
- RBAC and grants: layer principals get only required permissions (Browse/Read/Write as appropriate) and can run/manage relevant notebooks/jobs.
- Network boundaries: per-layer separation of duties across identity, storage, and compute to reduce blast radius.

## Operational concerns

- Monitoring/logging: enable Databricks system tables and Jobs monitoring UI for run/cost visibility.
- Cost controls: use autoscaling, auto-termination, and cluster policies per layer.
- CI/CD approach: implementation is explicitly deferred to Part II of the article.
- Backup/retention/disaster recovery strategy: not stated in article.

## Out-of-scope markers

- Part II is intended to cover CI/CD implementation and environment-promotion mechanics.

## Other observations

- The pattern strongly recommends managed tables for this design.
- The article emphasizes avoiding human-account dependency for production jobs.
- Secret rotation and audit logging are recommended as operational guardrails.

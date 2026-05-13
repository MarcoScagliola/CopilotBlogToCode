# Secure Medallion Architecture on Azure Databricks (Part I)

Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- High-level architecture pattern: medallion architecture (bronze, silver, gold) with security-first controls.
- Named components and roles:
  - Source systems feed ingestion into a bronze layer.
  - Silver layer performs standardized transformations.
  - Gold layer serves curated outputs for analytics consumption.
  - Databricks orchestrates pipeline execution.
- Data flow direction and triggers: batch progression bronze -> silver -> gold; exact production trigger cadence is not stated in article.
- Stated or implied data volume, frequency, latency: not stated in article.

## Azure services

- Azure Databricks: primary data engineering and orchestration platform.
- Azure Storage (ADLS Gen2 implied): per-layer data storage boundary for medallion zones.
- Azure Key Vault: secret and credential storage integrated with runtime.
- Microsoft Entra ID: identity and service principal boundary for least-privilege execution.
- For each service SKU/tier specifics: not stated in article.
- Networking posture:
  - Secure Cluster Connectivity (No Public IP) is required for workspace deployment.
  - Hybrid workspace type is referenced.
  - Private endpoint/firewall/service endpoint details are not stated in article.
- Region and redundancy (LRS/ZRS/GRS): not stated in article.

## Databricks

- Workspace tier: not stated in article.
- Workspace type: Hybrid.
- Secure Cluster Connectivity: enabled (No Public IP).
- Unity Catalog usage: implied yes for governed medallion access model; concrete metastore id is not stated in article.
- Catalog/schema names: not stated in article.
- Compute model: job clusters for setup and layer jobs.
- Jobs and orchestration:
  - Layered jobs for setup, bronze, silver, gold, smoke test.
  - Orchestrator dependency chain setup -> bronze -> silver -> gold -> smoke_test.
  - Schedule/concurrency constraints beyond default single-run are not stated in article.
- Lakeflow declarative pipelines usage: not stated in article.
- Task source format: Python files.
- Runtime/libraries/init scripts versions: not stated in article.

## Data model

- Source systems and formats: not stated in article.
- Target datasets grouped by layer: bronze, silver, gold logical outputs.
- Partitioning/liquid clustering/z-ordering: not stated in article.
- Schema evolution/enforcement rules: not stated in article.
- Data quality expectations: smoke-test style validation implied; detailed rules not stated in article.

## Security and identity

- Identities used:
  - Deployment principal for infrastructure provisioning.
  - Per-layer service principals for runtime separation (create mode in this run).
  - Databricks access connectors per layer for storage access.
- Secrets and storage:
  - Secrets are expected in Azure Key Vault and consumed through Databricks secret scope.
  - Exact secret key set is not stated in article.
- RBAC and grants:
  - Least-privilege model is required.
  - Exact role assignment matrix and Unity Catalog grants are not stated in article.
- Network boundaries and allowed paths: high-level secure boundary intent is stated; exact NSG and endpoint matrix is not stated in article.

## Operational concerns

- Monitoring/logging/alerting services: not stated in article.
- Cost controls (auto-termination, budgets, reservations): not stated in article.
- CI/CD approach in article: not stated in article.
- Backup/retention/disaster recovery strategy: not stated in article.

## Out-of-scope markers

- Production-specific operational hardening and full enterprise governance details are deferred/not fully specified in article.

## Other observations

- The article emphasizes secure-by-default medallion separation rather than one shared runtime identity.
- A practical implementation needs explicit decisions for region, catalog/schema naming, and secret key inventory before production rollout.

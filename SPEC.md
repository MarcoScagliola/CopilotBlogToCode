# Architecture Specification - Secure Medallion Pattern on Azure Databricks

Source article:
- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- High-level architecture pattern: secure medallion architecture with Bronze, Silver, and Gold layers, each isolated by identity, storage, and compute.
- Named components and roles:
  - Bronze job ingests raw data.
  - Silver job refines Bronze outputs.
  - Gold job aggregates Silver outputs.
  - Orchestrator job runs the layers in sequence.
- Data flow direction and triggers: sequential batch flow Bronze -> Silver -> Gold triggered by an orchestrator job; schedule not stated in article.
- Stated or implied data volume, frequency, and latency requirements: not stated in article.

## Azure services

- Azure Databricks: workspace hosting Lakeflow jobs and Unity Catalog-governed data assets.
- Azure Data Lake Storage Gen2: separate storage account per medallion layer for least-privilege data isolation.
- Azure Databricks Access Connector: per-layer managed identity bridge between Databricks and storage.
- Azure Key Vault: runtime secret store used through Databricks AKV-backed secret scopes.
- Microsoft Entra ID service principals: one per layer for execution isolation.
- Networking posture: secure cluster connectivity with no public IP is stated; broader private endpoint and firewall posture is not stated in article.
- Region and redundancy: not stated in article.

## Databricks

- Workspace tier: Premium inferred from Unity Catalog and security features; exact tier not explicitly stated.
- Workspace type Hybrid: not stated in article.
- Secure Cluster Connectivity (No Public IP): stated in article.
- Unity Catalog usage: yes.
  - Catalog names: separate Bronze, Silver, and Gold catalogs inferred from article guidance.
  - Schema names: not stated in article.
  - Metastore reference: not stated in article.
- Compute model: dedicated job clusters, one per layer, plus an orchestrator job.
- Jobs and orchestration: one job per layer plus an overarching orchestrator; schedules, triggers, and concurrency beyond single-run semantics are not stated in article.
- Lakeflow Spark Declarative Pipelines usage and mode: Lakeflow jobs are stated; triggered versus continuous mode is not stated in article.
- Task source format: not stated in article; this implementation uses Python files.
- Libraries, runtime version, init scripts: not stated in article.

## Data model

- Source systems and formats: not stated in article.
- Target datasets grouped by layer:
  - Bronze: raw ingestion table.
  - Silver: refined events table.
  - Gold: aggregated summary table.
- Partitioning or clustering strategy: not stated in article.
- Schema evolution or enforcement rules: not stated in article.
- Data quality expectations or test rules: article emphasizes progressive quality checks, but specific rules are not stated in article.

## Security and identity

- Identities used: Microsoft Entra ID service principals per layer, managed identities on Databricks access connectors.
- Secrets referenced and where they are stored: Azure Key Vault with Databricks AKV-backed secret scopes; secret keys themselves are not stated in article.
- RBAC assignments and Unity Catalog grants: least-privilege access is stated; exact grant matrix is not stated in article.
- Network boundaries: isolation between layers is stated; exact network path definitions are not stated in article.

## Operational concerns

- Monitoring, logging, alerting services referenced: Databricks Jobs monitoring UI, system tables, and Azure Key Vault diagnostics.
- Cost controls: dedicated compute per layer is stated; detailed autoscaling and cost settings are not stated in article.
- CI/CD or deployment approach: deferred to Part II of the blog series.
- Backup, retention, or disaster recovery strategy: not stated in article.

## Out-of-scope markers

- Detailed CI/CD implementation is deferred to Part II.
- Cluster reusability challenges are deferred.
- Environment promotion details are deferred.

## Other observations

- The article strongly prefers managed tables under Unity Catalog over external tables for the described design.
- The implementation should favor least privilege over convenience at every layer boundary.
- Secrets must be read only at runtime and never passed as job parameters.
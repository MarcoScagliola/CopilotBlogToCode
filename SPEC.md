# SPEC.md

## Source

- Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Source title: Secure Medallion Architecture Pattern on Azure Databricks (Part I)
- Article summary: The article presents a security-first Azure Databricks medallion pattern where Bronze, Silver, and Gold are isolated by separate storage, compute, and non-human identities. Unity Catalog, Lakeflow Jobs, Azure Key Vault, and Databricks Access Connectors provide the governance and execution model.
- Inferred architecture: Azure Databricks workspace plus Unity Catalog, three per-layer ADLS Gen2 accounts, three per-layer service principals, three per-layer clusters, one orchestrator job, and one Key Vault-backed secret scope per environment.

## Architecture

- High-level architecture pattern: secure medallion architecture with Bronze, Silver, and Gold processing layers.
- Named components and role each one plays:
  - Bronze stores raw immutable data from source systems.
  - Silver cleanses, filters, and reshapes Bronze data into business-ready models.
  - Gold publishes curated analytics-ready outputs for dashboards, reports, or APIs.
  - A Lakeflow orchestrator runs the three layer-specific jobs in order.
- Data flow direction and triggers: sequential multi-hop flow from Bronze to Silver to Gold, orchestrated by Lakeflow Jobs; exact trigger type and schedule are `not stated in article`.
- Data volume, frequency, and latency requirements: `not stated in article`.

## Azure services

- Azure Databricks: execution platform for Lakeflow Jobs and Unity Catalog-governed data processing.
- Azure Data Lake Storage Gen2: inferred from prose as the per-layer storage substrate; one storage account per Bronze, Silver, and Gold layer.
- Azure Key Vault: stores runtime secrets and backs the Databricks secret scope.
- Microsoft Entra ID: identity provider for deployment and per-layer service principals.
- Databricks Access Connector: explicit integration point for system-assigned managed identities that connect Databricks to Azure Storage.
- Networking posture:
  - Secure Cluster Connectivity / No Public IP for compute is explicit.
  - Private endpoints, firewall rules, service endpoints, VNet injection, and storage network ACL specifics are `not stated in article`.
- Region and redundancy: `not stated in article`.

## Databricks

- Workspace tier: `not stated in article`.
- Workspace type: hybrid is listed in the analysis checklist, but the article does not explicitly state a workspace type; treat as `not stated in article`.
- Secure Cluster Connectivity: explicit; deploy the workspace with No Public IP.
- Unity Catalog usage: explicit yes.
  - Separate catalogs for Bronze, Silver, and Gold are explicit.
  - Specific catalog names, schema names, and metastore identifiers are `not stated in article`.
- Compute model:
  - Three dedicated layer-specific clusters are explicit.
  - Bronze and Gold use general-purpose compute with Photon optional or often disabled.
  - Silver uses general-purpose compute with Photon enabled.
  - Exact node types, autoscaling bounds, and DBR versions are `not stated in article`.
- Jobs and orchestration:
  - Three Lakeflow Jobs, one per layer, are explicit.
  - One orchestrator Lakeflow is explicit.
  - Schedules, retry policy, concurrency, and notifications are `not stated in article`.
- Lakeflow Spark Declarative Pipelines usage: `not stated in article`.
- Task source format: notebooks are explicit in the text that discusses notebook permissions; Python file packaging is `not stated in article` and is a generator choice for this repository.
- Libraries, runtime version, and init scripts: `not stated in article`.

## Data model

- Source systems and formats: `not stated in article`.
- Target tables or datasets grouped by layer:
  - Bronze, Silver, and Gold datasets are explicit as a layered pattern.
  - Concrete table names and business subject areas are `not stated in article`.
- Partitioning and clustering strategy:
  - Managed tables are the chosen table type.
  - Automatic liquid clustering and Predictive Optimization are described as managed-table capabilities.
  - The article does not state a required partitioning, liquid-clustering, or Z-order rule for this workload.
- Schema evolution or enforcement rules: `not stated in article`.
- Data quality expectations:
  - Progressive data quality checks are explicit at the architectural level.
  - Concrete validation rules, thresholds, or test suites are `not stated in article`.

## Security and identity

- Identities used:
  - One deployment service principal is implied for CI/CD.
  - Three per-layer Microsoft Entra ID managed service principals are explicit.
  - Three Databricks Access Connectors with system-assigned managed identities are explicit.
- Secrets referenced and where they are stored:
  - Secrets are stored in Azure Key Vault.
  - Databricks reads them through an AKV-backed secret scope.
  - Specific secret keys and source-system credential inventory are `not stated in article`.
- RBAC assignments and Unity Catalog grants:
  - Least-privilege grants per layer are explicit.
  - Browse, Read File, and Write File privileges on source and target storage are explicit.
  - Exact Azure RBAC role names, UC grant statements, and group mappings are `not stated in article`.
- Network boundaries: per-layer isolation is explicit; exact network routes and boundary implementation details are `not stated in article`.

## Operational concerns

- Monitoring and logging:
  - Databricks system tables and Jobs monitoring UI are explicit.
  - Azure-native monitoring sinks such as Log Analytics or Application Insights are `not stated in article`.
- Cost controls:
  - Auto-termination, right-sizing, and cluster policies are explicit concepts.
  - Concrete quotas, budgets, or reserved-capacity settings are `not stated in article`.
- CI/CD and deployment approach:
  - The article explicitly says CI/CD code will be covered in Part II.
  - This repository generates its own workflows and treats CI/CD implementation as out of scope for Part I.
- Backup, retention, and disaster recovery strategy: `not stated in article`.

## Out-of-scope markers

- CI/CD code for deploying the pattern is deferred to Part II.
- Cluster reusability challenges are deferred to Part II.
- Environment promotion is deferred to Part II.

## Other observations

- The article prefers managed tables over external tables because managed tables simplify maintenance, optimize automatically, and obscure physical layout in storage.
- The article still requires external locations and storage credentials as part of the Unity Catalog setup model, which implies storage governance remains an important deployment concern even when managed tables are preferred.
- The repository implementation uses Python entrypoints rather than notebooks because the article does not provide runnable notebook code; this is an implementation choice, not a stated article requirement.
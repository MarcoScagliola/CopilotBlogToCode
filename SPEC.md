# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Short summary: the article describes a security-first medallion pattern on Azure Databricks. It splits Bronze, Silver, and Gold into separate Lakeflow jobs, uses dedicated Entra service principals per layer, stores secrets in Azure Key Vault, and prefers Unity Catalog managed tables with separate storage accounts per layer.

## Architecture

- High-level architecture pattern: explicit medallion architecture with Bronze, Silver, and Gold layers.
- Named components and the role each one plays: Bronze, Silver, and Gold jobs perform layer-specific processing; an orchestrator job chains them; Azure Data Lake Storage Gen2 provides per-layer storage; Azure Key Vault stores secrets; Unity Catalog governs catalogs, schemas, and managed tables; Databricks access connectors bridge workspace access to storage.
- Data flow direction and triggers: explicit sequential multi-hop flow from Bronze to Silver to Gold, orchestrated as Lakeflow Jobs. The article describes the jobs as repeatable code rather than ad hoc interactive runs.
- Stated or implied data volume, frequency, and latency requirements: not stated in article.

## Azure services

- Azure Databricks workspace: explicit; hosts Lakeflow Jobs, the medallion workloads, and Unity Catalog-backed access patterns. Workspace tier is inferred as Premium because Unity Catalog is used.
- Azure Data Lake Storage Gen2: explicit; separate storage accounts per layer are recommended so each layer has its own isolated storage boundary. Storage redundancy is assumed as LRS in the generated scaffold, but the article does not state a redundancy tier.
- Azure Key Vault: explicit; secrets are kept out of code and job parameters and are read at runtime through AKV-backed secret scopes.
- Azure Databricks Access Connector: inferred from the generated deployment contract and the article's workspace-to-storage governance model; one connector is provisioned per layer in the scaffold.
- Microsoft Entra ID service principals / managed identities: explicit; each layer uses a dedicated identity and the deployment principal is separate.
- Unity Catalog: explicit; the article calls for catalog.schema.table conventions, separate catalogs for Bronze/Silver/Gold, and managed tables.
- Networking posture: not stated in article.
- Region and redundancy: region not stated in article; redundancy tier not stated in article.

## Databricks

- Workspace tier: inferred Premium.
- Workspace type Hybrid: not stated in article.
- Deploy the Azure Databricks workspace with Secure Cluster Connectivity (No Public IP): not stated in article.
- Unity Catalog usage: yes; the generated scaffold uses inferred catalog names `blg_dev_bronze`, `blg_dev_silver`, and `blg_dev_gold`, with schemas `bronze`, `silver`, and `gold`.
- Compute model: Lakeflow Jobs with one job per layer, plus setup, orchestrator, and smoke-test jobs. Each layer runs on its own job cluster in the generated bundle.
- Jobs and orchestration: explicit multi-job orchestration, with one job per medallion layer plus an overarching orchestrator job. Schedules and concurrency limits beyond the single-run layer separation are not stated in article.
- Lakeflow Spark Declarative Pipelines usage and mode: not stated in article.
- Task source format: Python files under `databricks-bundle/src/<job>/main.py`.
- Libraries, runtime version, init scripts: not stated in article.

## Data model

- Source systems and formats: not stated in article.
- Target tables or datasets grouped by layer: the generated scaffold uses synthetic managed tables named `bronze_layer_runs`, `silver_layer_runs`, and `gold_layer_metrics` so the medallion flow can execute even though the article does not name concrete business tables.
- Do not apply Partitioning and rather use Liquid Clustering or Z-ordering strategy only if stated in the blog: not stated in article.
- Schema evolution or enforcement rules: not stated in article.
- Data quality expectations or test rules: the generated smoke test checks only that each table exists and has at least one row; the article does not define formal quality rules.

## Security and identity

- Identities used: explicit deployment Service Principal; explicit per-layer service principals; inferred Databricks access connector managed identities for storage access.
- Secrets referenced and where they are stored: explicit Azure Key Vault-backed Databricks secret scopes. The article does not name the secret keys, only the pattern of storing runtime secrets in Key Vault and reading them at runtime.
- RBAC assignments and Unity Catalog grants: least privilege is explicit, but the exact Azure RBAC roles and Databricks grants are not fully stated in the article.
- Network boundaries: not stated in article.

## Operational concerns

- Monitoring, logging, alerting services referenced: explicit use of system tables and the Jobs monitoring UI.
- Cost controls: not stated in article.
- CI/CD or deployment approach described in the article: the article points to a follow-up part for CI/CD and environment promotion; Part I does not define the implementation.
- Backup, retention, or disaster recovery strategy: not stated in article.

## Out-of-scope markers

- CI/CD implementation is deferred to Part II of the series.
- Environment promotion, cluster reusability, and deployment automation details are not covered in Part I.
- Exact source datasets, runtime secret keys, and downstream consumer tables are not named in the article.

## Other observations

- The article recommends one secret scope per environment and reading secrets at runtime with `dbutils.secrets.get(...)`.
- The generated scaffold uses synthetic medallion tables so the jobs can run end-to-end without inventing a source system that the article never named.
- Separate storage accounts per layer and separate clusters per layer are called out as part of the security and blast-radius story.
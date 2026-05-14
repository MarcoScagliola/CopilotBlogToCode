# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

## Source

- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetched: 2026-05-14
- Summary: The article proposes a secure Azure Databricks medallion design with strict layer isolation. Each Bronze, Silver, and Gold layer has dedicated storage, compute, and identity. Unity Catalog, Azure Key Vault, and Lakeflow jobs are used to enforce least privilege and operational separation.

## Architecture

- High-level architecture pattern: Medallion lakehouse (Bronze, Silver, Gold) with per-layer isolation.
- Named components and role:
  - Bronze layer: raw ingestion and append-focused persistence.
  - Silver layer: cleansing and business-conformed transformations.
  - Gold layer: curated data for BI and analytics consumption.
  - Orchestrator job: coordinates the three layer jobs in order.
- Data flow and triggers: Scheduled or triggered Lakeflow jobs with an orchestration layer; exact schedule not stated in article.
- Data volume/frequency/latency: not stated in article.

## Azure Services

- Azure Databricks: workspace and Lakeflow job execution platform.
- ADLS Gen2: three storage accounts, one per layer.
- Azure Key Vault: central secret storage and runtime secret retrieval.
- Microsoft Entra ID: layer service principals and managed identities.
- Azure Databricks Access Connector: layer-scoped identity bridge to storage for Unity Catalog operations.
- Networking posture:
  - Secure Cluster Connectivity (no public IP) is stated.
  - Private endpoints, NSG rules, and full network topology are not stated in article.
- Region and redundancy (LRS/ZRS/GRS): not stated in article.

## Databricks

- Workspace tier: not stated in article.
- Workspace type: hybrid workspace concept is referenced.
- Secure Cluster Connectivity (no public IP): explicitly stated.
- Unity Catalog usage: yes.
  - Separate catalogs per layer (Bronze, Silver, Gold) are explicitly recommended.
  - Specific catalog and schema names are not stated in article.
  - Metastore details are not stated in article.
- Compute model:
  - Three dedicated clusters, one per layer, explicitly recommended.
  - Cluster policies per layer are explicitly recommended.
  - Runtime versions and node SKUs are not stated in article.
- Jobs and orchestration:
  - Three Lakeflow jobs, one per layer, explicitly stated.
  - One orchestrator job, explicitly stated.
  - Exact schedules, retries, and concurrency values are not stated in article.
- Task source format: notebooks are explicitly discussed.
- Libraries and init scripts: not stated in article.

## Data Model

- Source systems and formats: not stated in article.
- Target datasets by layer: conceptual Bronze/Silver/Gold datasets are stated; concrete table names are not stated in article.
- Table type choice: managed tables are explicitly chosen.
- Partitioning and clustering strategy: liquid clustering is discussed conceptually; concrete table-level strategy is not stated in article.
- Schema evolution/enforcement details: not stated in article.
- Data quality tests/rules: conceptual quality gates by layer are implied; concrete rules not stated in article.

## Security and Identity

- Identities used:
  - Dedicated service principal per layer is explicitly stated.
  - Access connector / managed identity per layer is explicitly stated.
- Secrets and storage:
  - Secrets must be stored in Azure Key Vault.
  - Databricks AKV-backed secret scopes per environment are explicitly stated.
- RBAC and Unity Catalog grants:
  - Principle of least privilege is explicit.
  - Exact role-assignment matrix and grant statements are not stated in article.
- Network boundaries:
  - Layer isolation objective is explicit.
  - Exact routing and endpoint topology are not stated in article.

## Operational Concerns

- Monitoring and observability:
  - Databricks system tables and Jobs monitoring UI are explicitly recommended.
  - Azure Monitor and Log Analytics configuration details are not stated in article.
- Cost controls:
  - Cluster policies, per-layer sizing, and auto-termination are explicitly recommended.
  - Concrete cost budgets and SKU targets are not stated in article.
- CI/CD approach:
  - Part II will cover CI/CD code; concrete pipeline implementation is out of scope in this article.
- Backup/retention/DR strategy: not stated in article.

## Out-of-scope Markers

- CI/CD implementation details are deferred to Part II.
- Cluster reuse and environment promotion mechanics are deferred to Part II.

## Other Observations

- The article emphasizes blast-radius reduction through identity, storage, and compute segregation.
- The design assumes strong governance around catalog ownership, grants, and secret rotation policy, but these remain implementation-time decisions.
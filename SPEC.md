# Secure Medallion Architecture Pattern on Azure Databricks (Part I) - SPEC

Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Fetch timestamp (UTC): 2026-05-14

## Architecture

- High-level architecture pattern: secure medallion architecture with Bronze, Silver, Gold and a setup/orchestrator layer (stated in article).
- Named components and roles:
  - Source systems feed the bronze layer (source type specifics mostly not stated in article).
  - Bronze captures raw/landing data.
  - Silver performs validated/curated transformations from bronze.
  - Gold provides refined/consumption-ready data products.
  - Orchestrator coordinates per-layer jobs.
- Data flow direction and triggers:
  - Multi-hop Bronze -> Silver -> Gold flow (stated in article).
  - Job orchestration via Lakeflow Jobs, including per-layer jobs and an overarching orchestrator (stated in article).
  - Schedule cadence specifics are not stated in article.
- Data volume, frequency, latency requirements: not stated in article.

## Azure services

- Azure Databricks: core lakehouse compute and orchestration platform (stated in article).
- ADLS Gen2: per-layer storage isolation for bronze/silver/gold (stated in article).
- Azure Key Vault: central secret storage, accessed at runtime via AKV-backed scopes (stated in article).
- Microsoft Entra ID service principals / managed identities: per-layer identity isolation and least privilege (stated in article).
- Unity Catalog: governance backbone for catalogs/schemas/tables and permissions (stated in article).
- For each service configuration:
  - Databricks workspace configured with Secure Cluster Connectivity / no public IP (stated in article).
  - Storage is separated by layer (stated in article).
  - Key Vault diagnostics/logging is recommended (stated in article).
- Networking posture:
  - Secure cluster connectivity (no public IP) is stated in article.
  - Private endpoints, service endpoints, and explicit firewall matrix are not stated in article.
- Region and redundancy:
  - Article does not prescribe a specific region.
  - Current run uses uksouth from run inputs (not stated by article).
  - LRS/ZRS/GRS preferences are not stated in article.

## Databricks

- Workspace tier: not stated in article.
- Workspace type hybrid: yes (inferred from article checklist requirement and Azure Databricks deployment model).
- Secure Cluster Connectivity (No Public IP): stated in article.
- Unity Catalog usage: yes.
  - Separate bronze/silver/gold catalogs are recommended (stated in article).
  - Schema names are implied by medallion layer semantics and generated as bronze/silver/gold.
  - Metastore name/reference is not stated in article.
- Compute model:
  - Dedicated compute per layer (three isolated clusters/jobs) is stated in article.
  - Additional setup and smoke-test execution paths are added by this repo pattern.
- Jobs and orchestration:
  - One job per layer and one orchestrator job with dependencies (stated in article and aligned with repo generator).
  - Concurrency and full scheduling details are not stated in article.
- Lakeflow usage:
  - Lakeflow Jobs are explicitly referenced in article.
  - Triggered vs continuous specifics are not stated in article.
- Task source format: Python-based job tasks in this implementation (inferred from generated repo pattern).
- Runtime versions and library specifics: not stated in article.

## Data model

- Source systems and formats: not stated in article.
- Target datasets grouped by layer:
  - Bronze tables in bronze catalog/schema.
  - Silver tables in silver catalog/schema.
  - Gold tables in gold catalog/schema.
  - Exact business table names are not stated in article.
- Partitioning/clustering:
  - Article guidance prefers avoiding explicit partitioning and using liquid clustering or Z-order only if needed.
  - Concrete table-level clustering choices are not stated in article.
- Schema evolution/enforcement rules: not stated in article.
- Data quality expectations:
  - Progressive quality through medallion hops is stated conceptually.
  - Explicit rule catalog and thresholds are not stated in article.

## Security and identity

- Identities used:
  - Dedicated Entra ID service principal per data layer (stated in article).
  - Databricks access connector managed identities for storage/UC paths (stated or strongly implied by architecture discussion).
- Secrets and secret storage:
  - Secrets are stored in Azure Key Vault and read at runtime from AKV-backed secret scopes (stated in article).
- RBAC and UC grants:
  - Least privilege is mandatory and per-layer scoped (stated in article).
  - Exact role assignments and UC grants matrix are not fully enumerated in article.
- Network boundaries:
  - Separation of duties and blast-radius reduction across layer identities/compute/storage are stated in article.
  - Full network path diagram (private endpoints per service, NSG matrices) is not stated in article.

## Operational concerns

- Monitoring/logging/alerting:
  - Build observability from day one; use Jobs monitoring and system-table visibility guidance (stated in article).
  - Specific alert channels and thresholds are not stated in article.
- Cost controls:
  - Layer isolation and per-cluster controls are recommended conceptually.
  - Explicit budget mechanisms and reserved-capacity decisions are not stated in article.
- CI/CD approach:
  - Article indicates CI/CD implementation is deferred to Part II (stated in article).
  - This repository generates independent workflows for infra and DAB deployment.
- Backup/retention/disaster recovery strategy: not stated in article.

## Out-of-scope markers

- CI/CD implementation details are deferred to Part II (explicitly stated in article).
- Cluster reusability and environment promotion challenges are noted as later discussion (explicitly stated in article).

## Other observations

- The fetched page metadata title includes a non-article value due site framing, while page heading confirms the intended article title.
- The article emphasizes least privilege as the primary architectural principle and frames medallion boundaries as security boundaries, not only transformation stages.

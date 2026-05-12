# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- High-level architecture pattern:
  - Medallion architecture (Bronze, Silver, Gold) with security-first identity isolation by layer.
- Named components and roles:
  - Bronze layer: raw data ingestion and landing.
  - Silver layer: cleansed and conformed transformations.
  - Gold layer: curated analytics-ready data products.
  - Setup/orchestration layer: Unity Catalog objects and permissions setup before data processing.
- Data flow direction and triggers:
  - Batch-oriented flow from Bronze to Silver to Gold.
  - Job orchestration implied through Databricks jobs and dependencies.
- Data volume, frequency, latency:
  - not stated in article.

## Azure services

- Services named or depicted:
  - Azure Databricks workspace.
  - Azure Data Lake Storage Gen2 (separate storage per medallion layer).
  - Azure Key Vault (secret management).
  - Databricks Access Connector resources (one per layer) using system-assigned managed identities.
  - Microsoft Entra ID applications/service principals (one per layer when create mode is used).
- Service role, tier, configuration:
  - Databricks workspace tier: Premium (inferred from secure enterprise features discussed).
  - Workspace networking: Secure Cluster Connectivity (No Public IP) discussed.
  - ADLS Gen2: hierarchical namespace enabled, one account per layer.
  - Key Vault: standard usage for secret-backed integrations.
- Networking posture:
  - Secure Cluster Connectivity (No Public IP) is stated.
  - Private endpoints / firewall / service endpoints for each service: not stated in article.
- Region and redundancy:
  - Region: not stated in article.
  - Redundancy (LRS/ZRS/GRS): not stated in article.

## Databricks

- Workspace tier:
  - Premium (inferred from enterprise security posture and Unity Catalog alignment).
- Workspace type Hybrid:
  - not stated in article.
- Secure Cluster Connectivity (No Public IP):
  - Stated in article.
- Unity Catalog usage:
  - Yes. Separate catalogs/schemas for layers are implied by the medallion implementation pattern.
  - Metastore reference: not stated in article.
- Compute model:
  - Job clusters for layer processing are implied.
  - Serverless / SQL warehouse specifics: not stated in article.
- Jobs and orchestration:
  - Multi-stage orchestration: setup, bronze, silver, gold flow.
  - Exact schedules/triggers/concurrency values: not stated in article.
- Lakeflow Spark Declarative Pipelines usage:
  - not stated in article.
- Task source format:
  - Python file-based tasks are compatible with described approach; notebook preference not strictly stated.
- Libraries/runtime/init scripts:
  - not stated in article.

## Data model

- Source systems and formats:
  - not stated in article.
- Target datasets by layer:
  - Bronze raw datasets, Silver refined datasets, Gold curated aggregates.
  - Exact table names: not stated in article.
- Partitioning / Liquid Clustering / Z-order:
  - Liquid clustering references are implied in medallion optimization guidance.
  - Exact strategy per table: not stated in article.
- Schema evolution/enforcement:
  - not stated in article.
- Data quality expectations/tests:
  - High-level quality intent in silver/gold stages implied.
  - Concrete rule definitions: not stated in article.

## Security and identity

- Identity isolation:
  - One principal per layer (Bronze/Silver/Gold) is a core security control described in the article.
- Storage access model:
  - Least-privilege RBAC assignment per layer principal to corresponding ADLS account.
- Secret management:
  - Azure Key Vault-backed secret management is part of the pattern.
- Cross-layer access:
  - Segregation boundary is emphasized; broad cross-layer identity reuse is discouraged.

## CI/CD and operations

- Validation/deployment pipelines:
  - not stated in article.
- Environment promotion strategy:
  - not stated in article.
- Monitoring, alerting, observability:
  - not stated in article.
- Backup/DR:
  - not stated in article.

## Manual decisions required for this repo

- Region selection resolved to `uksouth` for this run.
- Naming conventions resolved by Terraform locals using `workload=blg`, `environment=dev`, `region_abbrev=uks`.
- Layer identity mode resolved to `create` for this run.

## Other observations

- The article focuses on secure architecture principles and separation of duties more than on concrete deployment automation.
- This repository must translate architecture intent into reproducible IaC and workflows, with unresolved values tracked in TODO.md.

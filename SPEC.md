# Secure Medallion Architecture Pattern on Azure Databricks - SPEC

## Source
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch timestamp: 2026-04-26 (local run)
- Summary: The article describes a security-first Azure Databricks medallion design where Bronze, Silver, and Gold are isolated by identity, storage, and compute, then orchestrated through Lakeflow jobs and governed with Unity Catalog and Key Vault-backed secret usage.

## Architecture
- High-level architecture pattern: medallion architecture with layered batch ELT and orchestration via Databricks Lakeflow jobs.
- Named components and roles:
  - Source systems: implied external systems feeding Bronze (not stated in article).
  - Bronze: ingestion and raw landing.
  - Silver: cleansing/refinement.
  - Gold: curated serving layer.
  - Orchestrator: runs Setup -> Bronze -> Silver -> Gold in sequence.
- Data flow direction and triggers: scheduled/triggered Lakeflow jobs (exact cron not stated in article).
- Data volume, frequency, latency requirements: not stated in article.

## Azure services
- Azure Databricks: primary compute and orchestration platform for medallion jobs.
- Azure Data Lake Storage Gen2: one storage account per medallion layer for isolation.
- Azure Key Vault: secret storage with runtime retrieval from Databricks.
- Microsoft Entra ID service principals / managed identities: least-privilege identities for layer execution.
- Azure Databricks Access Connector: bridge identity for Unity Catalog data access.
- Unity Catalog: governance backbone (catalog/schema/table model, grants, storage credentials).
- Networking posture:
  - Secure Cluster Connectivity / No Public IP for Databricks clusters: stated.
  - Private endpoints, VNet injection, firewall/service endpoints, NSG specifics: not stated in article.
  - Public network access setting for workspace: not stated in article.
- Region and redundancy (LRS/ZRS/GRS): not stated in article.

## Databricks
- Workspace tier (Standard/Premium): not stated in article.
- Workspace type hybrid: not stated in article.
- Deploy workspace with Secure Cluster Connectivity (No Public IP): stated.
- Unity Catalog usage: yes.
  - Catalog names: Bronze/Silver/Gold logical catalogs implied; concrete names not stated in article.
  - Schema names and metastore reference: not stated in article.
- Compute model:
  - Dedicated compute per layer: stated.
  - Single shared cluster is discouraged: stated.
  - Exact cluster SKU/runtime/policies: not stated in article.
- Jobs and orchestration:
  - One Lakeflow job per medallion layer plus orchestrator: stated.
  - Dependencies: implied sequential chaining setup -> bronze -> silver -> gold -> smoke_test.
  - Schedules/triggers/concurrency values: not stated in article.
- Lakeflow Spark Declarative Pipelines mode (triggered/continuous): not stated in article.
- Task source format: notebooks implied; Python files in this implementation are inferred from generated repository structure.
- Libraries/runtime/init scripts: not stated in article.

## Data model
- Source systems and formats: not stated in article.
- Target datasets grouped by layer:
  - Bronze raw ingestion table(s): inferred from medallion pattern.
  - Silver refined table(s): inferred from medallion pattern.
  - Gold curated aggregate/serving table(s): inferred from medallion pattern.
- Partitioning strategy:
  - Do not force partitioning unless specified.
  - Liquid clustering or Z-order only if stated: not stated in article.
- Schema evolution/enforcement rules: not stated in article.
- Data quality/test rules: not stated in article.

## Security and identity
- Identities used:
  - Dedicated Entra service principal per layer: stated.
  - Access connector managed identity for Databricks data access: stated.
- Secrets and storage:
  - Secrets in Azure Key Vault: stated.
  - Runtime retrieval through Databricks secret scopes: stated.
- RBAC and UC grants:
  - Least-privilege RBAC and UC grants per layer: stated at principle level.
  - Exact role definitions and grant statements: not stated in article.
- Network boundaries:
  - Layer-level isolation by identity, storage, and compute: stated.
  - Exact subnet routes and private-link topology: not stated in article.

## Operational concerns
- Monitoring/logging/alerting:
  - Enable Databricks system tables and jobs monitoring UI: stated.
  - AKV diagnostic logs: stated.
- Cost controls:
  - Track spend by layer via jobs/system tables: stated as recommendation.
  - Concrete budgets/reservations/autoscale limits: not stated in article.
- CI/CD approach:
  - Part I is architecture-focused; CI/CD implementation deferred to Part II.
- Backup/retention/DR strategy: not stated in article.

## Out-of-scope markers
- CI/CD implementation details are explicitly deferred to Part II.
- Production-grade environment promotion model is referenced but not fully specified in Part I.

## Other observations
- The article strongly recommends managed tables under Unity Catalog and notes GUID-obfuscated managed-table physical paths.
- Separation of duties is the core control objective: compromise in one layer should not grant write/read rights in adjacent layers.
- This implementation uses Terraform + Databricks Asset Bundle with generated GitHub workflows to operationalize the architecture in code.
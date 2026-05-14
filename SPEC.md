# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

## Source
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Title: Secure Medallion Architecture Pattern on Azure Databricks (Part I)
- Fetch date: 2026-05-14

## Architecture
- High-level architecture pattern: Secure Medallion (Bronze, Silver, Gold) with an orchestrator Lakeflow job.
- Named components and roles:
  - Bronze, Silver, Gold jobs isolate ingestion, refinement, and curation.
  - Separate storage and identities per layer enforce least privilege.
  - Unity Catalog governs external locations, credentials, and table access.
  - Azure Key Vault stores runtime secrets consumed via Databricks secret scopes.
- Data flow direction and triggers: Bronze -> Silver -> Gold, sequenced by an orchestrator Lakeflow job.
- Data volume, frequency, latency: not stated in article.

## Azure services
- Azure Databricks: core compute and orchestration platform with Lakeflow jobs.
- Azure Storage (ADLS Gen2): separate storage accounts per layer.
- Microsoft Entra ID: service principals and managed identity objects for non-human execution.
- Databricks Access Connector: managed identity bridge for storage access.
- Azure Key Vault: runtime secret storage with Key Vault-backed secret scopes.
- Networking posture:
  - Secure Cluster Connectivity / no public IP for clusters is explicitly recommended.
  - Private endpoints, firewall specifics, and VNet topology are not stated in article.
- Region and redundancy (LRS/ZRS/GRS): not stated in article.

## Databricks
- Workspace tier (Standard/Premium): not stated in article.
- Workspace type: Azure Databricks workspace (inferred from article context and services list).
- Secure Cluster Connectivity (No Public IP): explicitly required.
- Unity Catalog usage: yes.
  - Separate catalogs for bronze, silver, and gold are explicitly recommended.
  - Specific catalog names, schema names, and metastore ID are not stated in article.
- Compute model:
  - One dedicated cluster per layer (Bronze, Silver, Gold).
  - Three layer jobs plus one orchestrator job.
- Jobs and orchestration:
  - Layer jobs are orchestrated in sequence through an orchestrator Lakeflow job.
  - Schedule, trigger cron, and concurrency limits are not stated in article.
- Lakeflow mode (triggered vs continuous): not stated in article.
- Task source format: notebooks are referenced in provisioning guidance; Python file layout for this repo is inferred from bundle generator output.
- Runtime version, libraries, init scripts: not stated in article.

## Data model
- Source systems and formats: not stated in article.
- Target datasets grouped by layer:
  - Bronze: immutable raw tables.
  - Silver: refined business-conformed tables.
  - Gold: curated analytics-ready tables.
- Partitioning vs liquid clustering or z-ordering:
  - Managed tables are selected.
  - Liquid clustering and predictive optimization are discussed as managed-table capabilities, not as mandatory settings.
- Schema evolution/enforcement rules: not stated in article.
- Data quality/test rules: progressive quality checks across hops are implied; explicit rule set is not stated in article.

## Security and identity
- Identities used:
  - One service principal per layer (Bronze/Silver/Gold).
  - Access connector managed identities for storage credentials.
  - Deployment identity separated from runtime identities.
- Secrets and storage:
  - Secrets in Azure Key Vault.
  - Databricks Key Vault-backed secret scope per environment.
- RBAC and Unity Catalog grants:
  - Layer principals receive least-privilege access to only their layer resources.
  - Browse/Read/Write file grants are described per source/target context.
  - Exact role assignment matrix and principal IDs are not stated in article.
- Network boundaries:
  - Isolation by layer identity, storage, and compute is explicit.
  - Detailed network path controls are not stated in article.

## Operational concerns
- Monitoring/logging/alerting:
  - System tables and Jobs monitoring UI are explicitly recommended.
  - Diagnostic destinations and alert thresholds are not stated in article.
- Cost controls:
  - Auto-termination, right-sizing, and cluster policies are explicitly recommended.
- CI/CD approach:
  - Article references a follow-up part for CI/CD implementation details.
- Backup/retention/DR strategy: not stated in article.

## Out-of-scope markers
- Part II is announced for CI/CD implementation and additional operational challenges.

## Other observations
- Managed table choice is explicit due governance and optimization benefits.
- The pattern emphasizes separation of duties so a compromised upstream layer cannot modify downstream curated assets.

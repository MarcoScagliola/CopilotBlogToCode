# Architecture Specification - Secure Medallion Architecture Pattern on Azure Databricks

Generated from: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- High-level architecture pattern: Medallion Architecture (three data layers: Bronze, Silver, Gold) with per-layer isolation via dedicated service principals, storage accounts, and compute resources.
- Named components:
  - Bronze layer: raw data ingestion via Lakeflow Job, runs under Bronze service principal, writes to Bronze catalog using Managed Tables, reads secrets from Azure Key Vault
  - Silver layer: transformation and deduplication, reads from Bronze, writes to Silver catalog, runs under Silver service principal
  - Gold layer: aggregation and enrichment, reads from Silver, writes to Gold catalog, runs under Gold service principal
  - Orchestrator: master Lakeflow Job that coordinates Bronze → Silver → Gold → Smoke Test execution
- Data flow direction and triggers: batch ingestion via scheduled Lakeflow jobs (trigger frequency not stated in article); data flows bottom-up through layers (Bronze ingests, Silver transforms Bronze, Gold aggregates Silver)
- Data volume, frequency, latency requirements: not stated in article

## Azure services

- Azure Data Lake Storage Gen2 (ADLS Gen2): three separate storage accounts per layer (Bronze, Silver, Gold) for physical data residence and access isolation via Managed Identities
- Azure Key Vault: one per environment, stores secrets (e.g., source system credentials) referenced via AKV-backed Databricks secret scopes
- Azure Databricks: workspace with secure cluster connectivity (no public IP), Unity Catalog enabled, per-layer job clusters (one cluster per Bronze, Silver, Gold, plus orchestrator cluster)
- Access Connector for Azure Databricks (one per layer): integrates system-assigned managed identity (SAMI) between Databricks and ADLS Gen2 for least-privilege storage access
- Microsoft Entra ID / Managed Identities: three service principals (Bronze, Silver, Gold layer identities), plus system-assigned managed identities on Access Connectors
- SKU / tier: not stated in article (use standard defaults)
- Networking: Secure Cluster Connectivity enabled (no public IP on clusters), networking posture on workspace endpoints not stated in article
- Region and redundancy: not stated in article

## Databricks

- Workspace tier: Premium recommended (inferred from "strong security" emphasis); not explicitly stated as requirement
- Workspace type: not stated in article; assume standard workspace (not Serverless)
- Secure Cluster Connectivity: yes, explicitly stated "Deploy the Azure Databricks workspace with Secure Cluster Connectivity (No Public IP)"
- Unity Catalog usage: yes, required. Catalogs: bronze_catalog, silver_catalog, gold_catalog (inferred from naming convention); schemas: inferred as bronze_schema per layer; metastore reference not stated
- Compute model: Lakeflow Spark Declarative Pipelines (not traditional all-purpose clusters); one job cluster per layer, plus one for orchestrator
- Jobs and orchestration: four Lakeflow Jobs (bronze_job, silver_job, gold_job, orchestrator_job); orchestrator orchestrates the three layer jobs; single concurrency per job specified implicitly; schedules/triggers not stated in article
- Task source format: Python files (executed via Lakeflow spark_python_task)
- Libraries, runtime version, init scripts: not stated in article
- Cluster policy characteristics: mentioned as relevant but specific policies/configuration not detailed in article

## Data model

- Source systems and formats: not stated in article (marked as deployment-time decision); referenced as "source data" to be populated via Bronze job
- Target tables and schemas by layer:
  - Bronze: raw_events table (inferred), writes via append mode, stores raw ingestion data
  - Silver: events table (inferred), deduplicates and refines Bronze data, schema not detailed
  - Gold: event_summary table (inferred), aggregates by event type, higher-level insights
  - All tables: Unity Catalog Managed Tables (not external), separate catalogs per layer
- Partitioning and clustering: not stated in article
- Schema evolution rules: not stated in article
- Data quality tests: Smoke Test job validates that tables exist and contain rows; no formal data quality rules defined in article

## Security and identity

- Identities: three Entra ID service principals (Bronze, Silver, Gold layer identities); system-assigned managed identities (SAMIs) on per-layer Access Connectors; deployment principal identity (used for Terraform/DAB deployment)
- Authentication model: Microsoft Entra ID tokens via Entra-managed service principals; jobs authenticate via service principal client ID/secret stored in GitHub Secrets; no Databricks PATs required
- Secrets and secret storage: source system credentials (e.g., API tokens) stored in Azure Key Vault; accessed at runtime via Databricks AKV-backed secret scopes using dbutils.secrets.get(...); secret names and ingestion source details not stated in article
- RBAC assignments: inferred RBAC needed for service principals to access ADLS Gen2 (Storage Blob Data Contributor role); per-layer Access Connectors assigned system identities; specific Unity Catalog grants not detailed in article (marked as deployment-time configuration)
- Network boundaries: per-layer storage accounts restrict access via Storage Firewall (allow SAMI from Access Connector); Key Vault access restricted to authenticated service principals; no explicit network boundaries per layer stated

## Operational concerns

- Monitoring and logging: System tables recommended for tracking failures, durations, spend per layer; Jobs monitoring UI referenced; AKV diagnostic logs recommended; specific log retention or alerting not detailed
- Cost controls: auto-termination on clusters (mentioned in context of cluster reusability challenges); spot instances choice not mentioned; reserved capacity not mentioned
- CI/CD approach: article acknowledges "Part II" will publish CI/CD code; current article is conceptual/design only
- Backup and disaster recovery: not stated in article

## Out-of-scope markers

- Cluster reusability within Lakeflow Jobs (marked as "known challenges" for Part II)
- Environment promotion strategy beyond current environment modeling (deferred to Part II)
- Exact ingestion source and source format (left as deployment-time decision)
- Specific SLA/SLO targets and retry policies
- Full schema details and table designs for Silver and Gold layers
- Data quality validation rules beyond existence checks
- Secret rotation policies and implementation
- Multi-region failover and disaster recovery
- Production-grade monitoring dashboards and alerting thresholds

## Other observations

- Article emphasizes "security-first" and "least privilege" as primary design driver; every architectural choice is justified around reducing blast radius and isolation
- Managed Tables (as opposed to External Tables) are preferred for data governance and obfuscation of physical layout in ADLS Gen2
- Uses "Lakeflow Jobs" terminology (inferred as Databricks Lakehouse Jobs / declarative pipelines); execution model is batch scheduled jobs, not continuous pipelines
- Separation of duties applies to both identities (per-layer principals) and compute (per-layer clusters)
- Article is Part I of a series; implementation code deferred to Part II
- Per-layer storage accounts and Access Connectors are fundamental to enforce least-privilege storage access; not optional design elements

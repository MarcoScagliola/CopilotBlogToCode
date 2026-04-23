# SPEC — Secure Medallion Architecture on Azure Databricks

Source: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Fetch date: 2026-04-23

---

## Architecture

- **Pattern:** Medallion Architecture (Bronze → Silver → Gold), security-first variant.
- **Named components and roles:**
  - Bronze layer: raw ingestion job; reads from source systems; writes to `bronze` catalog managed tables.
  - Silver layer: deduplication/refinement job; reads Bronze; writes to `silver` catalog managed tables.
  - Gold layer: aggregation/serving job; reads Silver; writes to `gold` catalog managed tables.
  - Orchestrator job: triggers Bronze → Silver → Gold sequentially via Lakeflow run_job_task.
  - ADLS Gen2 (one storage account per layer): physical backing for Unity Catalog managed tables.
  - Azure Databricks Access Connector (one per layer): SAMI for Unity Catalog storage credential.
  - Azure Key Vault: runtime secrets store; accessed via AKV-backed Databricks secret scope.
  - Unity Catalog: governance backbone; separate catalog per layer.
  - Entra ID service principals: one per layer for job execution; least-privilege scoped to own layer.
- **Data flow:** Scheduled batch; orchestrator triggers Bronze → Silver → Gold in sequence.
- **Data volume / frequency / latency:** not stated in article.

## Azure Services

- **Azure Data Lake Storage Gen2** (one per layer: bronze, silver, gold)
  - Role: physical storage for UC managed tables per layer
  - SKU: Standard LRS (not stated; LRS inferred as default)
- **Azure Databricks workspace**
  - Role: hosts all Lakeflow jobs and Unity Catalog metastore
  - Tier: Premium (required for Unity Catalog)
- **Azure Databricks Access Connector** (one per layer)
  - Role: system-assigned managed identity bridging workspace to ADLS for UC storage credentials
- **Azure Key Vault** (one per environment)
  - Role: runtime secret store; AKV-backed Databricks secret scope
  - SKU: Standard; purge protection enabled (stated implicitly by soft-delete design)
- **Microsoft Entra ID service principals** (one per layer)
  - Role: job execution identity per layer; least-privilege RBAC
- **Networking posture:** not stated in article
- **Region:** not stated in article (set to `uksouth` per run context)
- **Redundancy:** not stated in article (LRS applied)

## Databricks

- **Workspace tier:** Premium (required for Unity Catalog — inferred from article)
- **Unity Catalog:** Yes
  - Catalogs: `{environment}_bronze`, `{environment}_silver`, `{environment}_gold`
  - Schemas: `ingestion` (bronze), `refined` (silver), `curated` (gold)
  - Table convention: `catalog.schema.table`
  - Managed tables (Unity Catalog GUID-based paths in ADLS)
  - Storage credentials via Access Connectors per layer
  - External locations per layer (ABFSS paths on ADLS)
- **Compute model:** Lakeflow job clusters (one dedicated cluster per layer)
  - `data_security_mode: USER_ISOLATION` required for Unity Catalog
  - Inferred from article: Standard_DS3_v2, 1 worker, autotermination 20 min
- **Jobs:**
  - `medallion-setup-{target}` — creates UC storage credentials, external locations, catalogs, schemas
  - `bronze-layer-{target}` — ingestion; reads source; writes `bronze_catalog.ingestion.raw_events`
  - `silver-layer-{target}` — refinement; reads bronze; writes `silver_catalog.refined.events`
  - `gold-layer-{target}` — aggregation; reads silver; writes `gold_catalog.curated.event_summary`
  - `medallion-orchestrator-{target}` — no-compute orchestrator; triggers above in sequence
- **Task source format:** Python files (spark_python_task)
- **Runtime:** 13.3.x LTS (inferred from article; Spark 3.4 / Scala 2.12)
- **Libraries / init scripts:** not stated in article

## Data Model

- **Source systems and formats:** not stated in article (sample raw_events table used)
- **Target tables by layer:**
  - Bronze: `{environment}_bronze.ingestion.raw_events` — raw ingest
  - Silver: `{environment}_silver.refined.events` — deduplicated/refined
  - Gold: `{environment}_gold.curated.event_summary` — aggregated summary
- **Table type:** Unity Catalog managed tables (GUID paths in ADLS; stated preference)
- **Partitioning / clustering / Z-order:** not stated in article
- **Schema evolution:** not stated in article
- **Data quality rules:** not stated in article

## Security and Identity

- **Identities:** Entra ID service principals (one per layer); Access Connectors (SAMI, one per layer)
- **Secrets:** Azure Key Vault; AKV-backed Databricks secret scope (`kv-{environment}-scope`)
  - Rule: secrets read only at runtime via `dbutils.secrets.get`; never logged, printed, or passed as plain job params
- **RBAC:**
  - Layer SP → `Storage Blob Data Contributor` on own layer storage account
  - Access Connector SAMI → `Storage Blob Data Contributor` on own layer storage account
  - Deployment SP → `Key Vault Secrets Officer` on Key Vault
- **Unity Catalog grants:** not stated in article (to be configured post-deployment)
- **Network boundaries:** not stated in article

## Operational Concerns

- **Monitoring:** Databricks system tables (`system.lakeflow`, `system.billing`) — stated
- **Jobs monitoring UI:** stated
- **Cost controls:** auto-termination (inferred from cluster design); budgets not stated
- **CI/CD:** Part II of article series — not included in this article
- **Backup / retention / DR:** not stated in article

## Out-of-Scope Markers

- Part II (CI/CD code and environment promotion) explicitly deferred by article
- Cluster reusability between Lakeflow jobs: noted as a "known challenge" for Part II
- Detailed cluster policy definitions: referenced but not specified

## Assumptions

- `layer_sp_mode=existing`: single deployment principal used for all layer identities in this run
- Terraform default variable `key_vault_recover_soft_deleted=true` for safe initial deployment
- LRS replication applied to all storage accounts
- Region: `uksouth` per run context
- Spark runtime: 13.3.x LTS
- Node type: Standard_DS3_v2, 1 worker

# SPEC — blg dev (Secure Medallion Architecture on Azure Databricks)

Source article: [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268)

Generated: 2026-05-12

---

## Architecture

- **High-level pattern**: Medallion (Bronze → Silver → Gold), security-first variant with per-layer identity isolation.
- **Named components and roles**:
  - Bronze layer: raw ingestion, append-only Delta managed tables, source data landing zone.
  - Silver layer: cleansing, transformation, integration into consistent business models (3NF / Data Vault).
  - Gold layer: curated analytics-ready datasets (dimensional/semantic model), BI/reporting output.
  - Orchestrator job: a fourth Lakeflow job that triggers the three layer jobs in sequence.
  - Unity Catalog: governance backbone — External Locations, storage credentials, managed tables, system-table observability.
- **Data flow direction and triggers**: batch, scheduled via Lakeflow Jobs. Bronze → Silver → Gold. Orchestrator job schedules and sequences the three layer Lakeflow jobs.
- **Data volume, frequency, latency requirements**: not stated in article.

---

## Azure services

- **ADLS Gen2 storage accounts**: 3, one per layer (Bronze, Silver, Gold). Role: backing store for Unity Catalog managed tables. SKU/tier: not stated in article. Transformed names: `stblgdevbronzeuks`, `stblgdevsilveruks`, `stblgdevgolduks`.
- **Azure Key Vault**: 1 per environment. Role: secret store for API keys, DB passwords, webhooks; backing AKV-backed secret scope in Databricks. Example names cited: `kv-dev`, `kv-prod`. Transformed canonical name: `kv-blg-dev-uks`.
- **Azure Databricks workspace**: 1. Tier: not stated explicitly; Unity Catalog requires Premium — inferred from architecture diagram. Canonical name: `dbw-blg-dev-uks`.
- **Databricks Access Connectors**: 3, one per layer. Role: system-assigned managed identity (SAMI) that enables Unity Catalog external location storage credentials. Names: `ac-blg-dev-bronze-uks`, `ac-blg-dev-silver-uks`, `ac-blg-dev-gold-uks`.
- **Microsoft Entra ID service principals**: 3, one per layer (Bronze SP, Silver SP, Gold SP). Created by Terraform when `layer_sp_mode=create`. Used as the runtime identity for each Lakeflow job.
- **Networking posture**: Secure Cluster Connectivity (No Public IP / SCC) stated. Private endpoints, VNet injection, NSG rules: not stated in article. Allow Public Network Access: not stated in article.
- **Region and redundancy**: region not stated in article (using `uksouth` from run input). Redundancy tier: not stated in article.

---

## Databricks

- **Workspace tier**: not stated in article — inferred Premium (Unity Catalog requires it).
- **Workspace type Hybrid**: not stated in article.
- **Secure Cluster Connectivity (No Public IP)**: stated — deploy with SCC enabled.
- **Unity Catalog**: yes.
  - Separate catalogs per layer: article names the pattern `bronze`, `silver`, `gold` — exact catalog names not stated in article.
  - Schema names: not stated in article. One schema per catalog implied.
  - Metastore reference: not stated in article (uses account-level default metastore).
- **Compute model**: 3 dedicated job clusters, one per layer (Bronze cluster, Silver cluster, Gold cluster) plus an orchestrator. Cluster characteristics:
  - Bronze: general-purpose / compute-optimised; Photon optional (disabled for most workloads).
  - Silver: general-purpose / compute-optimised; Photon enabled.
  - Gold: general-purpose / compute-optimised; Photon optional (disabled for most workloads).
  - Auto-termination, autoscaling, cluster policies: stated as recommended but not quantified.
- **Jobs and orchestration**: 4 Lakeflow jobs — Bronze, Silver, Gold, and Orchestrator. Orchestrator uses `run_job_task` to trigger the three layer jobs. Schedules: not stated in article. Concurrency: not stated in article.
- **Lakeflow Spark Declarative Pipelines**: not used — standard Lakeflow Jobs (not DLT pipelines).
- **Task source format**: Python files (entrypoints under `databricks-bundle/src/<layer>/main.py`).
- **Libraries, runtime version, init scripts**: not stated in article.

---

## Data model

- **Source systems and formats**: not stated in article.
- **Target tables by layer**:
  - Bronze: managed Delta tables, append-only, optionally enriched with technical metadata fields. Table names: not stated in article.
  - Silver: managed Delta tables, cleaned/transformed to consistent business model (3NF or Data Vault). Table names: not stated in article.
  - Gold: managed Delta tables, analytics-ready (dimensional or semantic layer). Table names: not stated in article.
- **Table type**: managed tables — explicitly chosen. Unity Catalog manages both metadata and data; GUID-based paths in ADLS Gen2.
- **Liquid clustering**: stated — Automatic liquid clustering (CLUSTER BY AUTO) for managed tables on DBR 15.4 LTS+. Predictive Optimization and Automatic statistics also enabled.
- **Partitioning / Z-ordering**: not stated in article — not applied.
- **Schema evolution or enforcement rules**: not stated in article.
- **Data quality expectations or test rules**: not stated in article.

---

## Security and identity

- **Identities used**:
  - 3 Microsoft Entra ID service principals (one per layer: Bronze SP, Silver SP, Gold SP). Entra-managed, authenticating via Entra ID tokens (not PATs).
  - 3 Databricks Access Connectors with SAMI (system-assigned managed identity), one per layer. Used as Unity Catalog storage credentials.
  - Deployment service principal: used by Terraform to provision all resources.
- **Secrets storage**: Azure Key Vault (one per environment) + AKV-backed Databricks secret scope (one per environment, e.g. `kv-dev`). Secret scope name: not stated in article.
- **Key Vault secrets expected** (inferred from architecture): API keys, DB passwords, webhooks. Exact secret key names: not stated in article.
- **RBAC assignments**:
  - Each layer SP: Storage Blob Data Contributor (or least-privilege equivalent) on its own storage account only.
  - Each Access Connector SAMI: Storage Blob Data Contributor on its layer's storage account (for Unity Catalog External Location).
  - Layer SPs are granted `Can Run` on their Lakeflow job; `Can Manage` as needed (inferred from article).
  - Unity Catalog External Location grants: Browse, Read File on source; Browse, Read File, Write File on target (per layer).
  - Unity Catalog privilege model: not fully specified in article — see TODO.md.
- **Network boundaries**: SCC (No Public IP) for Databricks. Each layer SP/cluster can only reach its own storage and External Location. Cross-layer access blocked by permission design.

---

## Operational concerns

- **Monitoring**: system tables enabled — `system.lakeflow/*` (runs, tasks, timelines) and `system.billing/*`. Jobs monitoring UI for run history, task details, and notifications.
- **Cost controls**: right-size clusters per layer; autoscaling and auto-termination stated as recommended; cluster policies per layer. Reserved capacity / budgets: not stated in article.
- **CI/CD**: explicitly deferred to Part II of the article series. This orchestrator generates its own workflows independently of Part II.
- **Backup, retention, DR**: not stated in article.

---

## Out-of-scope markers

- CI/CD deployment tooling explicitly deferred to Part II of the article.
- Cluster reusability across Lakeflow jobs deferred to Part II.
- Environment promotion strategy deferred to Part II.

---

## Other observations

- Article uses "Lakeflow" as the current name for Databricks Workflows/Jobs (previously called "Workflows").
- The pattern strongly advocates for External Locations in Unity Catalog per layer (not managed external tables — managed tables are used, but storage is accessed via External Locations backed by Access Connector SAMIs).
- Article prescribes one secret scope per environment with consistent key names across environments (e.g., `api-token`, `db-password`).
- AKV diagnostic logs recommended for audit; secret access should be validated in non-production before promoting.
- Article explicitly recommends against sharing a single cluster or single service principal across layers.
- Naming transformations applied:
  - Article examples `kv-dev` / `kv-prod` → canonical `kv-blg-dev-uks` (terraform skill Section 5 naming).
  - Storage account names use no hyphens and are lowercase: `stblgdevbronzeuks`, `stblgdevsilveruks`, `stblgdevgolduks`.
  - Workspace: `dbw-blg-dev-uks`.
  - Resource group: `rg-blg-dev-uks`.

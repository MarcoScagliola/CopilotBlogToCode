# SPEC — blg dev (Secure Medallion Architecture on Azure Databricks)

Source article: [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268)

Generated: 2026-05-12

Inputs used: workload=blg, environment=dev, azure_region=uksouth, layer_sp_mode=existing

---

## Architecture

- **High-level pattern**: Medallion (Bronze → Silver → Gold), security-first variant with per-layer identity isolation.
- **Named components and roles**:
  - Bronze layer: raw ingestion, append-only Delta managed tables, source data landing zone.
  - Silver layer: cleansing, transformation, integration into consistent business models.
  - Gold layer: curated analytics-ready datasets (dimensional/semantic model), BI/reporting output.
  - Setup job: Unity Catalog object registration (External Locations, catalogs, schemas) executed before layer jobs.
  - Orchestrator: Lakeflow job that sequences the layer jobs.
- **Data flow direction and triggers**: batch, scheduled via Lakeflow Jobs; Bronze → Silver → Gold; orchestrator sequences the three layer jobs.
- **Data volume, frequency, latency requirements**: not stated in article.

---

## Azure services

- **ADLS Gen2 storage accounts**: 3, one per layer (Bronze, Silver, Gold). HNS enabled. SKU/tier: not stated in article. Canonical names: `stblgdevbronzeuks`, `stblgdevsilveruks`, `stblgdevgolduks`.
- **Azure Key Vault**: 1 per environment. Stores runtime secrets (API keys, passwords, webhooks); backs AKV-backed Databricks secret scope. Canonical name: `kv-blg-dev-uks`.
- **Azure Databricks workspace**: 1. Tier: not stated explicitly; Unity Catalog requires Premium — inferred from architecture. Canonical name: `dbw-blg-dev-uks`.
- **Databricks Access Connectors**: 3, one per layer. System-assigned managed identity (SAMI). Canonical names: `ac-blg-dev-bronze-uks`, `ac-blg-dev-silver-uks`, `ac-blg-dev-gold-uks`.
- **Microsoft Entra ID service principals**: 3, one per layer (when `layer_sp_mode=existing`, these are pre-created by the operator). Runtime identity for each Lakeflow job.
- **Networking posture**: Secure Cluster Connectivity (No Public IP / SCC) stated. Private endpoints, VNet injection: not stated in article.
- **Region and redundancy**: region not stated in article (resolved to `uksouth` from run input). Redundancy tier: not stated in article.

---

## Databricks

- **Workspace tier**: not stated in article — inferred Premium (Unity Catalog requires it).
- **Workspace type Hybrid**: not stated in article.
- **Secure Cluster Connectivity (No Public IP)**: stated.
- **Unity Catalog**: yes. Per-layer catalogs and schemas implied. Metastore reference: not stated in article.
- **Compute model**: 3 dedicated job clusters (one per layer) plus an orchestrator. Cluster characteristics not quantified in article.
- **Jobs and orchestration**: 4 Lakeflow jobs — Setup, Bronze, Silver, Gold (+ Orchestrator). Schedules, concurrency: not stated in article.
- **Lakeflow Spark Declarative Pipelines**: not used — standard Lakeflow Jobs.
- **Task source format**: Python files (`databricks-bundle/src/<layer>/main.py`).
- **Libraries, runtime version, init scripts**: not stated in article.

---

## Data model

- **Source systems and formats**: not stated in article.
- **Target tables by layer**: Bronze: append-only Delta managed tables; Silver: cleansed/conformed; Gold: analytics-ready aggregates. Table names: not stated in article.
- **Liquid clustering**: implied for managed Delta tables. Exact strategy: not stated in article.
- **Schema evolution/enforcement**: not stated in article.
- **Data quality rules**: not stated in article.

---

## Security and identity

- One Entra ID SP per layer (pre-created by operator when `layer_sp_mode=existing`); one Access Connector SAMI per layer.
- Each layer SP: Storage Blob Data Contributor on its own ADLS account only.
- Each Access Connector SAMI: Storage Blob Data Contributor on its layer's ADLS account (for Unity Catalog External Location).
- AKV-backed Databricks secret scope (one per environment). Exact scope name: not stated in article.
- Unity Catalog privilege model: not fully specified in article.

---

## Operational concerns

- Monitoring: system tables (`system.lakeflow/*`, `system.billing/*`) recommended; not configured in generated code.
- CI/CD: deferred to Part II of article series.
- Backup, retention, DR: not stated in article.

---

## Other observations

- Article explicitly recommends against sharing a single cluster or SP across layers.
- Naming transformations: `kv-dev` / `kv-prod` examples in article → canonical `kv-blg-dev-uks` (terraform skill Section 5).
- Resource group: `rg-blg-dev-uks`. Workspace: `dbw-blg-dev-uks`.
- `layer_sp_mode=existing` selected: three layer service principals must be pre-created by the operator before deploy. The Terraform configuration accepts a single shared existing principal (via `EXISTING_LAYER_SP_CLIENT_ID` / `EXISTING_LAYER_SP_OBJECT_ID`) or a split principal set. See REPO_CONTEXT.md for fallback rules.

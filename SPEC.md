# SPEC — Secure Medallion Architecture Pattern on Azure Databricks (Part I)

**Source:** https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
**Fetched:** 2026-05-12
**Workload:** blg | **Environment:** dev | **Region:** uksouth | **layer_sp_mode:** create

---

## Architecture

- **Pattern:** Security-first Medallion Architecture (Bronze → Silver → Gold)
- **Named components and roles:**
  - ADLS Gen2 (×3): per-layer storage accounts (Bronze, Silver, Gold), each isolated
  - Azure Databricks Access Connector (×3): system-assigned managed identity per layer, bridges SAMI to Unity Catalog
  - Microsoft Entra ID Service Principals (×3): one per layer, used to run Lakeflow Jobs; least-privilege access to their own layer only
  - Azure Key Vault: secret store for runtime credentials; AKV-backed Databricks secret scope
  - Databricks Premium Workspace: host for Unity Catalog, Lakeflow Jobs, clusters
  - Unity Catalog: governance layer (catalogs + schemas per layer)
  - Lakeflow Jobs (×4): 3 per-layer jobs (bronze, silver, gold) + 1 overarching orchestrator job
- **Data flow:** orchestrator job triggers bronze → bronze triggers silver → silver triggers gold (inferred from architecture description: sequential layered execution)
- **Triggers / schedules:** `not stated in article` — article says jobs are deployed in paused state; schedules not specified
- **Data volume / frequency / latency:** `not stated in article`

## Azure services

- **Storage Account (×3):** ADLS Gen2 (Hierarchical Namespace = true); one per layer (bronze, silver, gold); tier/SKU not stated → defaulting to Standard LRS per naming convention
- **Azure Databricks Access Connector (×3):** system-assigned managed identity; one per layer; used to grant Unity Catalog access to ADLS Gen2
- **Azure Key Vault (×1):** Standard tier (inferred from standard deployment pattern); soft-delete enabled; used for AKV-backed Databricks secret scope
- **Azure Databricks Workspace (×1):** Premium tier (stated implicitly — Unity Catalog requires Premium); Secure Cluster Connectivity (No Public IP) stated explicitly
- **Networking posture:** SCC/No Public IP on workspace; no VNet injection, private endpoints, or firewall rules stated → `not stated in article` for private endpoints / firewall rules; Allow Public Network Access not explicitly addressed
- **Region:** `not stated in article` (resolved to uksouth per inputs)
- **Redundancy:** `not stated in article` (defaulting to Standard LRS)

## Databricks

- **Workspace tier:** Premium (required for Unity Catalog; inferred from Unity Catalog usage)
- **SCC / No Public IP:** yes — stated explicitly
- **Unity Catalog:** yes — catalog.schema.table convention; separate catalogs for Bronze, Silver, Gold
  - Catalog names: `not stated in article` (defaulting to `bronze`, `silver`, `gold`)
  - Schema names: `not stated in article` (defaulting to `main` per layer)
  - Managed tables chosen (article explicitly prefers managed tables over external tables)
- **Compute model:** job clusters (one dedicated cluster per layer — stated explicitly); cluster per-layer isolation enforced
- **Jobs and orchestration:** 4 Lakeflow Jobs — bronze, silver, gold (one each), plus an orchestrator that triggers all three via `run_job_task`; max_concurrent_runs=1 per job
- **Schedules:** `not stated in article`
- **Task source format:** Python files (inferred from architecture pattern; article does not mention notebooks or SQL)
- **Cluster policies:** `not stated in article` — article mentions policies as a benefit but does not specify them
- **Libraries / runtime / init scripts:** `not stated in article`; spark_version defaulting to 13.3.x-scala2.12

## Data model

- **Source systems and formats:** `not stated in article`
- **Target tables:** `not stated in article` (managed tables under bronze/silver/gold catalogs + schemas)
- **Partitioning / Liquid Clustering / Z-ordering:** `not stated in article`
- **Schema evolution:** `not stated in article`
- **Data quality rules:** `not stated in article`

## Security and identity

- **Identities used:**
  - 3 × Entra ID service principals (one per layer, bronze/silver/gold) — created by Terraform in `create` mode
  - 3 × Azure Databricks Access Connectors with system-assigned managed identities (one per layer)
  - Deployment service principal (from GitHub Secrets) — provisions all infrastructure
- **SP display names (create mode):** `sp-blg-dev-bronze-uks`, `sp-blg-dev-silver-uks`, `sp-blg-dev-gold-uks`
- **Secrets:**
  - Runtime credentials stored in Azure Key Vault; read at runtime via AKV-backed Databricks secret scope
  - Secret names: `not stated in article`
  - One secret scope per environment; consistent key naming recommended in article
- **RBAC / Unity Catalog grants:**
  - Access connectors → `Storage Blob Data Contributor` on their layer's storage account
  - Layer SPs → `Storage Blob Data Reader` or `Contributor` on their layer's storage (RBAC details not fully stated)
  - Unity Catalog privilege model: `not stated in article` (article mentions least-privilege; specific GRANT statements not given)
- **Network boundaries:** article isolates per-layer identities; Bronze identity cannot access Silver/Gold storage

## Operational concerns

- **Monitoring:** article mentions system tables and Jobs monitoring UI; diagnostic logs on Key Vault recommended; `not stated in article` for Log Analytics workspace
- **Cost controls:** `not stated in article` (auto-termination mentioned conceptually; no specific minute values given)
- **CI/CD:** article defers to Part II; this skill generates its own workflows
- **Backup / retention / DR:** `not stated in article`

## Out-of-scope markers

- Cluster reusability / Lakeflow job cluster sharing: explicitly deferred to Part II
- Environment promotion: explicitly deferred to Part II
- CI/CD code: explicitly deferred to Part II

## Other observations

- Article explicitly chooses Managed Tables over External Tables to obfuscate physical storage layout
- Article advocates one secret scope per environment with consistent key names
- `purge_protection_enabled = true` will be set on Key Vault (one-way flag; terraform skill mandates this)
- `shared_access_key_enabled = true` on storage accounts during provisioning (AzureRM provider requires it; post-deploy hardening step in TODO.md)

---

## Resolved naming (canonical, from terraform skill Section 5)

| Resource | Canonical name |
|---|---|
| Resource group | `rg-blg-dev-uks` |
| Key Vault | `kv-blg-dev-uks` |
| Databricks workspace | `dbw-blg-dev-uks` |
| Storage — Bronze | `stblgdevbronzeuks` |
| Storage — Silver | `stblgdevsilveruks` |
| Storage — Gold | `stblgdevgolduks` |
| Access Connector — Bronze | `ac-blg-dev-bronze-uks` |
| Access Connector — Silver | `ac-blg-dev-silver-uks` |
| Access Connector — Gold | `ac-blg-dev-gold-uks` |
| SP — Bronze (create mode) | `sp-blg-dev-bronze-uks` |
| SP — Silver (create mode) | `sp-blg-dev-silver-uks` |
| SP — Gold (create mode) | `sp-blg-dev-gold-uks` |
| Secret scope | `kv-dev-scope` |
| GitHub Environment | `BLG2CODEDEV` |

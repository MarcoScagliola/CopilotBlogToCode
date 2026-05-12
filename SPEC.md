# SPEC — blg Secure Medallion Architecture on Azure Databricks

Source: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Fetched: 2026-05-12
`layer_sp_mode`: create

---

## Architecture

- **Pattern**: Medallion Architecture (Bronze → Silver → Gold). Each layer is an isolated pipeline stage.
- **Components and roles**:
  - 3× ADLS Gen2 storage accounts — one per layer (bronze, silver, gold); sole storage backend for that layer.
  - 3× Azure Databricks Access Connectors (System-Assigned Managed Identity) — bridge between Databricks and layer storage.
  - 3× Microsoft Entra ID Service Principals — one per layer; least-privilege runtime identity for each Lakeflow job.
  - Azure Key Vault — secrets store; surfaced to notebooks and jobs via a Key Vault-backed Databricks secret scope.
  - Azure Databricks workspace — Premium tier; hosts Unity Catalog, access connectors, and Lakeflow jobs.
  - Unity Catalog — governance layer; one catalog per layer (bronze, silver, gold); managed tables used.
  - Lakeflow Jobs — 4 jobs total: one orchestrator job triggering three layer jobs (bronze, silver, gold) via `run_job_task`.
- **Data flow**: Sequential batch. Orchestrator triggers Bronze → Silver → Gold in order.
- **Data volume / frequency / latency**: not stated in article.

## Azure services

- **Azure Data Lake Storage Gen2** (3 accounts):
  - Role: per-layer data storage; HNS=true required by Unity Catalog External Location pattern.
  - SKU/tier: not stated in article. Generated default: Standard LRS.
  - One account per layer; article explicitly advocates "separate storage accounts per layer".
- **Azure Key Vault**:
  - Role: runtime secrets store for credentials; article states "Store them in Azure Key Vault".
  - SKU/tier: not stated in article. Generated default: Standard, soft-delete enabled (7-day purge protection not stated; Azure default 90-day applies).
  - One vault per environment ("one secret scope per environment" — inferred from article).
- **Azure Databricks workspace**:
  - Role: host for Unity Catalog, access connectors, compute, and Lakeflow jobs.
  - Tier: Premium (inferred from Unity Catalog requirement; Premium required for UC).
  - Secure Cluster Connectivity / No Public IP: stated — "Deploy the Azure Databricks workspace with Secure Cluster Connectivity (No Public IP)".
- **Azure Databricks Access Connectors** (3):
  - Role: provide a system-assigned managed identity per layer for Unity Catalog storage credential.
  - Identity type: SystemAssigned (inferred from "system-assigned managed identity (SAMI)" article text).
- **Microsoft Entra ID App Registrations / Service Principals** (3, `layer_sp_mode=create`):
  - Role: one dedicated Entra ID SP per layer; "executed by a dedicated Microsoft Entra ID service principal".
  - Named by layer: bronze, silver, gold.
- **Networking posture**: SCC / No Public IP stated. Private endpoints: not stated. VNet injection: not stated. Firewall rules: not stated. Public Network Access on storage: not stated.
- **Region**: uksouth (operator-supplied). Redundancy: not stated in article.

## Databricks

- **Workspace tier**: Premium (inferred from Unity Catalog requirement).
- **Workspace type**: Secure Cluster Connectivity (No Public IP) — explicitly stated.
- **Unity Catalog**:
  - Usage: yes.
  - Catalog names: `bronze`, `silver`, `gold` (one per layer — stated: "create separate catalogs for Bronze, Silver, and Gold").
  - Schema names: not stated in article. Generated default: `main` per catalog.
  - Metastore: not stated in article (workspace-level default assumed).
  - Table type: managed tables — explicitly stated ("Azure Databricks Managed Tables will be our choice").
- **Compute model**:
  - 3 dedicated clusters, one per layer — stated: "provision three(3) dedicated clusters, one(1) per layer".
  - Cluster specs (size, autoscaling, DBR version): not stated in article.
  - Cluster policies: not stated in article.
- **Jobs and orchestration**:
  - 4 Lakeflow Jobs: `bronze_ingestion`, `silver_transform`, `gold_aggregate`, and `orchestrator`.
  - Orchestrator uses `run_job_task` to trigger the three layer jobs in sequence.
  - Schedules: not stated in article.
  - Concurrency / retries: not stated in article.
- **Lakeflow Spark Declarative Pipelines**: not used. Article uses standard Lakeflow Jobs (not DLT/pipelines).
- **Task source format**: Python files (inferred from architecture pattern; article does not specify notebooks vs Python files explicitly but mentions "notebooks" in passing for secret reading; Python files used in generated bundle).
- **Libraries / runtime version / init scripts**: not stated in article.

## Data model

- **Source systems and formats**: not stated in article.
- **Target tables**: managed tables in Unity Catalog per layer. Bronze table(s), Silver table(s), Gold table(s) — specific names not stated in article.
- **Table naming / folder structure**: Unity Catalog GUID-based paths for managed tables; article provides example ADLS folder structure for illustration only.
- **Partitioning / clustering / Z-ordering**: not stated in article.
- **Schema evolution**: not stated in article.
- **Data quality expectations**: not stated in article. Article mentions "progressive data quality checks" as a benefit of medallion pattern but does not define specific rules.

## Security and identity

- **Identities**:
  - 1 deployment Service Principal (operator-supplied).
  - 3 Entra ID Service Principals (one per layer; created by Terraform when `layer_sp_mode=create`): `sp-blg-dev-bronze-uks`, `sp-blg-dev-silver-uks`, `sp-blg-dev-gold-uks`.
  - 3 Access Connectors with System-Assigned Managed Identity (one per layer).
- **Secrets**:
  - Azure Key Vault-backed Databricks secret scope.
  - Article: "one secret scope per environment".
  - Secret scope name convention: `kv-dev-scope` (generated default).
  - Article does not specify which secret keys the entrypoints read (source system credentials are architecture-specific and not stated).
- **RBAC assignments**:
  - Each layer SP: `Storage Blob Data Contributor` on its layer's storage account (inferred from least-privilege requirement).
  - Each Access Connector SAMI: `Storage Blob Data Contributor` on its layer's storage account (inferred from Access Connector pattern).
  - Deployment SP: Key Vault access policy for secret management.
  - Layer SPs: Key Vault access policy for `Get` / `List` (inferred from runtime secret reading).
  - Specific Unity Catalog grants: not stated in article.
- **Network boundaries**: SCC workspace (no public IP for cluster nodes). Storage account network restrictions: not stated. Key Vault network restrictions: not stated.

## Operational concerns

- **Monitoring**: system tables recommended ("Enable system tables") — stated. Jobs monitoring UI — stated. Specific Log Analytics workspace or Application Insights: not stated in article.
- **Cost controls**: not stated in article.
- **CI/CD**: explicitly deferred to Part II of the series ("In Part II, we'll publish CI/CD code to deploy this pattern").
- **Backup / retention / DR**: not stated in article.

## Out-of-scope markers

- CI/CD details: explicitly deferred to Part II.
- "Cluster reusability Lakeflow jobs": called out as a "known challenge" for Part II.
- Data disposition tier (beyond Gold): mentioned as an additional tier "not shown in the diagram".

## Other observations

- Article is Part I of a series; Part II covers CI/CD deployment code and cluster reusability.
- Managed tables preferred over external tables — explicitly stated with rationale (GUID-based paths obfuscate physical layout).
- "One secret scope per environment" — explicitly stated as a best practice.
- AKV diagnostic logs recommended for audit — stated but not a deployment requirement.
- Article uses the term "Lakeflow Jobs" consistently (the Databricks Jobs product). Lakeflow Spark Declarative Pipelines (DLT) are not used.
- Disclaimer in article: "views in this article are my own and do not represent Microsoft or Databricks."

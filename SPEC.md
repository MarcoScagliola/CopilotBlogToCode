# Secure Medallion Architecture on Azure Databricks – Infrastructure Specification

**Generated:** April 13, 2026  
**Source:** [Secure Medallion Architecture Pattern on Azure Databricks, Part I](https://techcommunity.microsoft.com/blog/analyticsonaxure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268)  
**Workload:** blg | **Environment:** dev | **Region:** uksouth (uks)

---

## Executive Summary

This specification describes the infrastructure-as-code (IaC) deployment of a secure medallion architecture (Bronze–Silver–Gold data lake) on Azure Databricks, aligned with Microsoft security and governance best practices. The architecture emphasizes:

- **Multi-layer isolation:** Separate storage accounts and managed identities per data layer (Bronze ingest, Silver transformation, Gold aggregation)
- **Least-privilege access:** Service principals scoped to individual storage accounts via RBAC role assignments
- **Unity Catalog governance:** Separate catalogs, schemas, and managed tables per layer with external location credentials
- **Secret management:** Azure Key Vault–backed Databricks secret scope for JDBC connection pooling
- **Job orchestration:** Lakeflow jobs chained via an orchestrator task with per-job service principal spark_conf
- **Infrastructure ownership:** Terraform manages all Azure resources and UC metadata; Databricks Asset Bundle manages jobs and notebooks

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Azure Subscription                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Resource Group: rg-blg-dev-uks                              │  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │ Azure Data Lake Storage Gen2 (3x Storage Accounts)    │ │  │
│  │  ├────────────────────────────────────────────────────────┤ │  │
│  │  │ • stblgbrzdev  (Bronze Layer – Raw Data)             │ │  │
│  │  │ • stblgslvdev  (Silver Layer – Cleansed Data)        │ │  │
│  │  │ • stblgglddev  (Gold Layer – Aggregated Data)        │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │ Azure Key Vault (KV storage for JDBC secrets)         │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                                                              │  │
│  │  ┌───────────────────────────────────┐                      │  │
│  │  │ Databricks Workspace               │                      │  │
│  │  │ dbw-blg-dev-uks                   │                      │  │
│  │  ├───────────────────────────────────┤                      │  │
│  │  │ • Account: <account_id>           │                      │  │
│  │  │ • Unity Catalog Enabled           │                      │  │
│  │  │ • Metastore ID: <metastore_id>    │                      │  │
│  │  └───────────────────────────────────┘                      │  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │ Databricks Access Connectors (3x)                      │ │  │
│  │  ├────────────────────────────────────────────────────────┤ │  │
│  │  │ • dbac-blg-brz-dev-uks → stblgbrzdev                 │ │  │
│  │  │ • dbac-blg-slv-dev-uks → stblgslvdev                 │ │  │
│  │  │ • dbac-blg-gld-dev-uks → stblgglddev                 │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │ Entra ID Service Principals (3x)                       │ │  │
│  │  ├────────────────────────────────────────────────────────┤ │  │
│  │  │ • sp-blg-bronze-dev-uks (bronze_sp_client_id)        │ │  │
│  │  │ • sp-blg-silver-dev-uks (silver_sp_client_id)        │ │  │
│  │  │ • sp-blg-gold-dev-uks   (gold_sp_client_id)          │ │  │
│  │  │                                                        │ │  │
│  │  │ RBAC Assignments:                                      │ │  │
│  │  │ • SPN-Bronze → Storage Blob Data Contributor (Bronze) │ │  │
│  │  │ • SPN-Silver → Storage Blob Data Contributor (Silver) │ │  │
│  │  │ • SPN-Gold   → Storage Blob Data Contributor (Gold)   │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │ Unity Catalog Configuration                             │ │  │
│  │  ├────────────────────────────────────────────────────────┤ │  │
│  │  │ Catalogs:                                              │ │  │
│  │  │ • blg_bronze (external location + storage cred)      │ │  │
│  │  │ • blg_silver (external location + storage cred)      │ │  │
│  │  │ • blg_gold   (external location + storage cred)      │ │  │
│  │  │                                                        │ │  │
│  │  │ Schemas per catalog:                                  │ │  │
│  │  │ • blg_bronze.raw_data (managed tables)               │ │  │
│  │  │ • blg_silver.curated_data (managed tables)           │ │  │
│  │  │ • blg_gold.analytics (managed tables)                │ │  │
│  │  │                                                        │ │  │
│  │  │ AKV Secret Scope:                                      │ │  │
│  │  │ • blg-dev-uks-akv (for JDBC credentials)             │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │ Databricks Jobs (DAB-managed)                           │ │  │
│  │  ├────────────────────────────────────────────────────────┤ │  │
│  │  │ • blg-bronze-ingest (task: JDBC source read)          │ │  │
│  │  │ • blg-silver-transform (task: dedup, filter nulls)   │ │  │
│  │  │ • blg-gold-aggregate (task: GROUP BY aggregation)    │ │  │
│  │  │ • blg-orchestrator (task: job chain + checkpoint)    │ │  │
│  │  │                                                        │ │  │
│  │  │ Job Configuration:                                     │ │  │
│  │  │ • Each job has spark_conf with service principal key │ │  │
│  │  │ • Orchestrator uses run_job_task for chaining        │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Resource Naming Convention

Naming follows [Cloud Adoption Framework (CAF)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging) conventions derived from **workload**, **environment**, and **azure_region**.

| Resource Type | Pattern | Example |
|---|---|---|
| Resource Group | `rg-{workload}-{environment}-{region_abbr}` | `rg-blg-dev-uks` |
| Workspace | `dbw-{workload}-{environment}-{region_abbr}` | `dbw-blg-dev-uks` |
| Storage Account (Layer) | `st{workload}{layer_abbr}{environment}` | `stblgbrzdev`, `stblgslvdev`, `stblgglddev` |
| Key Vault | `kv-{workload}-{environment}-{region_abbr}` | `kv-blg-dev-uks` |
| Access Connector | `dbac-{workload}-{layer_abbr}-{environment}-{region_abbr}` | `dbac-blg-brz-dev-uks` |
| Service Principal | `sp-{workload}-{layer}-{environment}-{region_abbr}` | `sp-blg-bronze-dev-uks` |
| UC Catalog | `{workload}_{layer}` | `blg_bronze`, `blg_silver`, `blg_gold` |
| UC Schema | `{layer_name}_data` | `raw_data`, `curated_data`, `analytics` |
| AKV Secret Scope | `{workload}-{environment}-{region_abbr}-akv` | `blg-dev-uks-akv` |

**Region Abbreviations:**
- uksouth → uks
- eastus → eus
- westeurope → weu
- etc. (configurable in locals.tf)

---

## Data Flow

```
[Source Database]
        ↓
   [JDBC Ingest]
        ↓
[Bronze Layer: stblgbrzdev]
   blg_bronze.raw_data
        ↓
[Silver Transform: Dedup, Filter]
[Silver Layer: stblgslvdev]
   blg_silver.curated_data
        ↓
[Gold Aggregate: GROUP BY, SUM]
[Gold Layer: stblgglddev]
   blg_gold.analytics
        ↓
[Checkpoint Table: Timestamp + Success Flag]
```

---

## Terraform Structure

| File | Purpose |
|---|---|
| `infra/terraform/versions.tf` | Provider version constraints (azurerm ~3.110, azuread ~2.52, databricks ~1.52) |
| `infra/terraform/providers.tf` | Provider authentication and configuration (account-level + workspace-level Databricks) |
| `infra/terraform/variables.tf` | Input variables (mandatory: tenant_id, subscription_id, account_id, metastore_id, JDBC credentials) |
| `infra/terraform/locals.tf` | Derived resource names from workload/environment/region; hardcoded inputs |
| `infra/terraform/main.tf` | Azure resources: RG, storage, KV, access connectors, SPs, RBAC, workspace, UC catalogs/schemas/credentials |
| `infra/terraform/outputs.tf` | Handoff values: workspace URL/ID, SP client IDs, catalog names, secret scope name |

**Provider Versions:**
- `azurerm`: ~3.110
- `azuread`: ~2.52
- `databricks`: ~1.52

**Terraform Locals (All Computed):**
All resource naming is computed in `locals.tf` from inputs, following CAF conventions. No resource names in variables.

---

## Databricks Asset Bundle (DAB) Structure

| File | Purpose |
|---|---|
| `databricks-bundle/databricks.yml` | Bundle definition, targets (dev/prod), variables, workspace/catalog/schema/SP/secret scope mappings |
| `databricks-bundle/resources/jobs.yml` | Four Lakeflow job definitions with task dependencies |
| `databricks-bundle/src/bronze/main.py` | JDBC read via jaydebeapi + sqlalchemy; parameterized source table; write to Bronze managed table |
| `databricks-bundle/src/silver/main.py` | Read Bronze catalog.schema.table; dedup on source_id; filter nulls; write to Silver managed table |
| `databricks-bundle/src/gold/main.py` | Read Silver; GROUP BY category; SUM metrics; write to Gold managed table |
| `databricks-bundle/src/orchestrator/main.py` | Write UTC timestamp and success flag to checkpoint table |

**DAB Variables:**
- `workspace_host`: Databricks workspace URL (from Terraform output)
- `bronze_catalog`, `silver_catalog`, `gold_catalog`: UC catalog names
- `bronze_schema`, `silver_schema`, `gold_schema`: UC schema names
- `bronze_sp_client_id`, `silver_sp_client_id`, `gold_sp_client_id`: Service principal client IDs
- `secret_scope`: AKV-backed secret scope name (blg-dev-uks-akv)
- `source_table_name`: Source JDBC table name (from TODO)
- `alert_email`: Notification email for job failures (from TODO)

---

## Unity Catalog Configuration

### External Locations
Each catalog has an external location pointing to its storage account:

```
blg_bronze_external_location → abfss://raw@stblgbrzdev.dfs.core.windows.net/
blg_silver_external_location → abfss://curated@stblgslvdev.dfs.core.windows.net/
blg_gold_external_location → abfss://analytics@stblgglddev.dfs.core.windows.net/
```

### Storage Credentials
Each catalog has a storage credential tied to its access connector and service principal:

```
blg_bronze_credential (access connector → stblgbrzdev)
blg_silver_credential (access connector → stblgslvdev)
blg_gold_credential (access connector → stblgglddev)
```

### Catalogs and Schemas

**blg_bronze**
- External location: `blg_bronze_external_location`
- Storage credential: `blg_bronze_credential`
- Schema: `raw_data` (managed tables only)

**blg_silver**
- External location: `blg_silver_external_location`
- Storage credential: `blg_silver_credential`
- Schema: `curated_data` (managed tables only)

**blg_gold**
- External location: `blg_gold_external_location`
- Storage credential: `blg_gold_credential`
- Schema: `analytics` (managed tables only)

---

## Security & Access Model

### Service Principal Isolation

Each service principal is scoped to its own storage account via RBAC:

| Service Principal | Role | Scope |
|---|---|---|
| sp-blg-bronze-dev-uks | Storage Blob Data Contributor | stblgbrzdev |
| sp-blg-silver-dev-uks | Storage Blob Data Contributor | stblgslvdev |
| sp-blg-gold-dev-uks | Storage Blob Data Contributor | stblgglddev |

### Databricks Job Authentication

Each Databricks job runs with Lakeflow's native service principal execution model via `spark_conf`:

```python
"spark.databricks.cluster.profile": "singleNode",
"spark.databricks.sqlanalytics.clusters.multiplex.enabled": "true",
"<layer>_sp_client_id": "<client_id>"  # Per job, injected from DAB variable
```

### Key Vault Secret Scope

Databricks AKV-backed secret scope (`blg-dev-uks-akv`) stores JDBC connection credentials:

- Secrets: `jdbc_host`, `jdbc_database`, `jdbc_user`, `jdbc_password`
- Access: Cluster-level (all clusters can read; Databricks-managed encryption)

---

## Handoff Between Terraform and DAB

### Terraform Outputs → DAB Variables

After `terraform apply` completes, capture outputs and map to DAB variables:

```yaml
# From Terraform
databricks_workspace_url → workspace_host
bronze_sp_client_id → bronze_sp_client_id
silver_sp_client_id → silver_sp_client_id
gold_sp_client_id → gold_sp_client_id
uc_catalog_bronze → bronze_catalog
uc_catalog_silver → silver_catalog
uc_catalog_gold → gold_catalog
secret_scope_name → secret_scope
```

### Deployment Sequence

1. **Terraform**: Deploy infra and UC catalogs/schemas/credentials
2. **Inject outputs**: Extract Terraform outputs → `databricks-bundle/databricks.yml`
3. **DAB**: Deploy jobs and notebooks

---

## Unresolved Values (See TODO.md)

- Azure tenant ID
- Azure subscription ID
- Databricks account ID
- Databricks metastore ID
- JDBC host, database, username, password
- Source table name
- Alert email address

---

## Deployment Assumptions

1. **Azure pre-requisites**: Subscription, Resource Group, Entra ID access
2. **Databricks pre-requisites**: Account, metastore created, account-level auth configured
3. **JDBC source**: Available, network-accessible from Databricks clusters
4. **GitHub Environment**: `BLG2CODEDEV` configured with AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID secrets
5. **Terraform CLI**: Installed and authenticated to Azure
6. **Databricks CLI**: Installed and authenticated to Databricks account

---

## Related Documentation

- [Azure Databricks Security Best Practices](https://learn.microsoft.com/en-us/azure/databricks/security/)
- [Unity Catalog Documentation](https://docs.databricks.com/en/data-governance/unity-catalog/index.html)
- [CAF Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Databricks Asset Bundles (DAB)](https://docs.databricks.com/en/dev-tools/bundles/index.html)

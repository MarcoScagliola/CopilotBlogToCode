# Secure Medallion Architecture on Azure Databricks – SPEC

## 1. Pattern Overview

This implementation follows the **Secure Medallion Architecture** pattern described in the Microsoft Azure Tech Community blog. The pattern applies Unity Catalog-enforced data governance across three storage layers (Bronze, Silver, Gold), with each layer isolated by a dedicated Entra ID Service Principal, Access Connector, and Unity Catalog external location. All secrets are stored in Azure Key Vault and surfaced to Databricks via a Key Vault-backed secret scope – no credentials are embedded in code.

The architecture enforces **least-privilege per-layer access**: the Bronze SP can only read/write the Bronze catalog, the Silver SP is scoped to Silver, and the Gold SP to Gold. Cross-layer data flows are coordinated by a Databricks Lakeflow orchestrator job, not by sharing identities.

---

## 2. Component Inventory

### Azure Infrastructure (Terraform-managed)

| Component | Name | Purpose |
|---|---|---|
| Resource Group | `rg-blg-dev-uks` | Container for all Azure resources |
| Databricks Workspace | `dbw-blg-dev-uks` | Premium workspace with Unity Catalog enabled |
| Storage Account – Bronze | `stblgbrzdev` | ADLS Gen2, HNS enabled, LRS |
| Storage Account – Silver | `stblgslvdev` | ADLS Gen2, HNS enabled, LRS |
| Storage Account – Gold | `stblgglddev` | ADLS Gen2, HNS enabled, LRS |
| Access Connector – Bronze | `dbac-blg-brz-dev-uks` | Managed identity for Bronze UC storage credential |
| Access Connector – Silver | `dbac-blg-slv-dev-uks` | Managed identity for Silver UC storage credential |
| Access Connector – Gold | `dbac-blg-gld-dev-uks` | Managed identity for Gold UC storage credential |
| Entra App – Bronze | `app-blg-brz-dev` | Identity for Bronze layer SP |
| Entra App – Silver | `app-blg-slv-dev` | Identity for Silver layer SP |
| Entra App – Gold | `app-blg-gld-dev` | Identity for Gold layer SP |
| Key Vault | `kv-blg-dev-uks` | Stores JDBC credentials and SP secrets |

### Unity Catalog Objects (Terraform-managed via Databricks provider)

| Object Type | Name | Scope |
|---|---|---|
| Metastore Assignment | workspace → metastore | Workspace-level |
| Storage Credential – Bronze | `sc-blg-brz-dev` | Access Connector managed identity |
| Storage Credential – Silver | `sc-blg-slv-dev` | Access Connector managed identity |
| Storage Credential – Gold | `sc-blg-gld-dev` | Access Connector managed identity |
| External Location – Bronze | `el-blg-brz-dev` | `abfss://bronze-data@stblgbrzdev.dfs.core.windows.net/` |
| External Location – Silver | `el-blg-slv-dev` | `abfss://silver-data@stblgslvdev.dfs.core.windows.net/` |
| External Location – Gold | `el-blg-gld-dev` | `abfss://gold-data@stblgglddev.dfs.core.windows.net/` |
| Catalog – Bronze | `blg_brz_dev` | Bronze layer catalog |
| Catalog – Silver | `blg_slv_dev` | Silver layer catalog |
| Catalog – Gold | `blg_gld_dev` | Gold layer catalog |
| Schema – Bronze | `bronze_schema` | Inside `blg_brz_dev` |
| Schema – Silver | `silver_schema` | Inside `blg_slv_dev` |
| Schema – Gold | `gold_schema` | Inside `blg_gld_dev` |

### Databricks DAB Assets (DAB-managed)

| Component | Name | Purpose |
|---|---|---|
| Lakeflow Job – Bronze | `job-blg-brz-dev` | JDBC ingestion → Bronze catalog |
| Lakeflow Job – Silver | `job-blg-slv-dev` | Deduplication + cleanse → Silver catalog |
| Lakeflow Job – Gold | `job-blg-gld-dev` | GROUP BY aggregation → Gold catalog |
| Lakeflow Job – Orchestrator | `job-blg-orch-dev` | Chains Bronze→Silver→Gold, writes checkpoint |

---

## 3. Security Model

### Least-Privilege Per-Layer SP Isolation

Each medallion layer has an exclusive Entra Application and Service Principal. Terraform grants each SP only `USE_CATALOG`, `USE_SCHEMA`, `CREATE_TABLE`, and `CREATE_VOLUME` on their **own** catalog and schema. No SP has cross-layer grants.

```
Bronze SP → blg_brz_dev catalog + bronze_schema only
Silver SP → blg_slv_dev catalog + silver_schema only
Gold SP   → blg_gld_dev catalog + gold_schema only
```

### Access Connector Isolation

Each layer's ADLS Gen2 storage account is accessed via a dedicated Azure Databricks Access Connector with a system-assigned managed identity. Terraform assigns `Storage Blob Data Contributor` on the specific storage account, not at subscription or resource-group scope.

### Secret Management

- All credentials (JDBC host, database, user, password; SP secrets) are stored in Azure Key Vault
- Databricks accesses them through a Key Vault-backed secret scope (`kv-blg-dev`)
- Jobs reference secrets as `{{secrets/kv-blg-dev/<key>}}` – no plaintext in code or config
- No secrets are passed as Spark configuration values in cleartext

### Network Boundary

All storage accounts and Key Vault use private-endpoint-ready configuration (ADLS Gen2 HNS + standard SKU). Network-level hardening (private endpoints, VNet injection) is deferred to the production environment.

---

## 4. Unity Catalog Structure

```
Databricks Account
└── Unity Catalog Metastore (pre-existing)
    └── Workspace: dbw-blg-dev-uks
        ├── Catalog: blg_brz_dev
        │   └── Schema: bronze_schema
        │       └── Tables: <source_table_name> (Delta, managed)
        ├── Catalog: blg_slv_dev
        │   └── Schema: silver_schema
        │       └── Tables: <source_table_name> (Delta, managed)
        └── Catalog: blg_gld_dev
            └── Schema: gold_schema
                ├── Tables: aggregated (Delta, managed)
                └── Tables: pipeline_checkpoint (Delta, managed)
```

---

## 5. Data Flow

```
External Source (JDBC/SQL)
         │
         ▼ [Bronze SP + JDBC credentials from KV]
  Bronze Ingestion Job (job-blg-brz-dev)
         │  append + mergeSchema
         ▼
  blg_brz_dev.bronze_schema.<source_table>  (ADLS: stblgbrzdev)
         │
         ▼ [Silver SP]
  Silver Transform Job (job-blg-slv-dev)
         │  deduplicate + dropna → overwrite
         ▼
  blg_slv_dev.silver_schema.<source_table>  (ADLS: stblgslvdev)
         │
         ▼ [Gold SP]
  Gold Aggregate Job (job-blg-gld-dev)
         │  GROUP BY category + SUM numerics → overwrite
         ▼
  blg_gld_dev.gold_schema.aggregated        (ADLS: stblgglddev)
         │
         ▼ [Orchestrator – no data access SP]
  blg_gld_dev.gold_schema.pipeline_checkpoint  (UTC timestamp + run status)
```

The Orchestrator job (`job-blg-orch-dev`) uses `run_job_task` to chain the three layer jobs sequentially. It does not use a layer SP – only the deployment principal writes to the checkpoint table.

---

## 6. Secrets Management Summary

| Secret | Key Vault Secret Name | Databricks Scope Key |
|---|---|---|
| JDBC hostname | `jdbc-host` | `jdbc-host` |
| JDBC database | `jdbc-database` | `jdbc-database` |
| JDBC user | `jdbc-user` | `jdbc-user` |
| JDBC password | `jdbc-password` | `jdbc-password` |
| Bronze SP secret | `bronze-sp-secret` | `bronze-sp-secret` |
| Silver SP secret | `silver-sp-secret` | `silver-sp-secret` |
| Gold SP secret | `gold-sp-secret` | `gold-sp-secret` |
| Entra Tenant ID | `tenant-id` | `tenant-id` |

> SP secrets (`bronze-sp-secret`, etc.) must be created manually in Key Vault after `terraform apply`, using the client secrets generated for each Entra Application. Add to TODO.md.

---

## 7. Deployment Boundary

| Layer | Owns |
|---|---|
| Terraform | Azure resources, Entra apps/SPs, Key Vault, RBAC, Databricks workspace, UC credentials/locations/catalogs/schemas/grants |
| Databricks Asset Bundle (DAB) | Lakeflow jobs, job clusters, Python entrypoints |

This boundary is enforced: no Terraform-managed UC resources appear in `databricks.yml`, and no jobs or notebooks appear in Terraform.

# SPEC — Secure Medallion Architecture on Azure Databricks

## Source
[Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268)

## Architecture Summary

The pattern enforces least-privilege isolation across a Bronze → Silver → Gold medallion pipeline by assigning each layer its own Microsoft Entra ID service principal, dedicated compute cluster, and independent ADLS Gen2 storage account. No single identity or cluster spans multiple layers. An orchestrator Lakeflow Job sequences the three layer jobs without directly accessing data.

## Azure Resources (Terraform)

| Resource | Count | Notes |
|---|---|---|
| Resource Group | 1 | All resources co-located |
| Azure Databricks Workspace | 1 | Premium SKU, Unity Catalog |
| ADLS Gen2 Storage Accounts | 3 | One per layer, HNS enabled, shared-key disabled |
| Storage Containers | 3 | One per layer, private |
| Databricks Access Connectors | 3 | System-assigned managed identity per layer |
| Azure Key Vault | 1 | RBAC-authorised, purge-protection enabled |
| Entra App Registrations | 3 | One per layer (bronze, silver, gold) |
| Entra Service Principals | 3 | One per layer, registered in Databricks workspace |

## RBAC Assignments (Terraform)

| Principal | Role | Scope |
|---|---|---|
| Bronze Access Connector MI | Storage Blob Data Contributor | Bronze storage account |
| Silver Access Connector MI | Storage Blob Data Contributor | Silver storage account |
| Silver Access Connector MI | Storage Blob Data Reader | Bronze storage account |
| Gold Access Connector MI | Storage Blob Data Contributor | Gold storage account |
| Gold Access Connector MI | Storage Blob Data Reader | Silver storage account |
| Bronze SP | Key Vault Secrets User | Key Vault |
| Silver SP | Key Vault Secrets User | Key Vault |
| Gold SP | Key Vault Secrets User | Key Vault |

## Unity Catalog Objects (Terraform via Databricks provider)

| Object | Count | Notes |
|---|---|---|
| Storage Credentials | 3 | Backed by Access Connector MI per layer |
| External Locations | 3 | Points to `abfss://<container>@<storage>.dfs.core.windows.net/` |
| Catalogs | 3 | One per layer with `storage_root` pointing to external location |
| Schemas | 3 | One per catalog |

## Databricks Jobs (DAB)

| Job | Run As | Cluster | Purpose |
|---|---|---|---|
| `job-blg-brz-<env>` | Bronze SP | Dedicated 1–2 nodes, STANDARD engine | JDBC ingestion → Bronze Delta table |
| `job-blg-slv-<env>` | Silver SP | Dedicated 1–3 nodes, PHOTON engine | Dedup + cleanse → Silver Delta table |
| `job-blg-gld-<env>` | Gold SP | Dedicated 1–2 nodes, STANDARD engine | Daily aggregation → Gold Delta table |
| `job-blg-orch-<env>` | No run_as (orchestrator) | Serverless | Sequences bronze → silver → gold |

## Secrets

All source credentials are stored in Azure Key Vault and read at runtime via an AKV-backed Databricks secret scope. Secret keys:
- `jdbc-host`
- `jdbc-database`
- `jdbc-user`
- `jdbc-password`

## Naming Convention

All names derived in `locals.tf` from `workload`, `environment`, `azure_region`. No names accepted as Terraform input variables.

## Deployment Flow

1. **Validate** — `validate-terraform.yml`: `terraform init -backend=false && terraform validate`
2. **Infra** — `deploy-infrastructure.yml`: `terraform apply` → uploads `terraform-outputs.json` artifact
3. **Bundle** — `deploy-dab.yml`: downloads artifact, deploys DAB using SP auth via workspace resource ID

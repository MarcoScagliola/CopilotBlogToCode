# SPEC – Secure Medallion Architecture on Azure Databricks

**Source**: [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268)

## Architecture Summary

The pattern implements a **security-first Medallion Architecture** on Azure Databricks where Bronze, Silver, and Gold each run as independent Lakeflow jobs under their own dedicated Microsoft Entra ID service principal. No single principal, cluster, or job has full access across all layers. If a layer is compromised, the blast radius is contained to that layer alone.

## Infrastructure Scope (Terraform)

| Resource | Count | Purpose |
|---|---|---|
| Resource Group | 1 | Boundary for all layer resources |
| ADLS Gen2 Storage Account | 3 (per layer) | Isolated physical storage per layer |
| Databricks Access Connector | 3 (per layer) | Exposes SAMI to Unity Catalog for storage access |
| Azure Key Vault | 1 | Stores JDBC and runtime secrets |
| Databricks Workspace (Premium) | 1 | Single workspace; isolation enforced via Unity Catalog |
| Entra ID Application / SP | 3 (per layer, create mode) | Least-privilege layer identities |
| Unity Catalog Metastore | 1 | Governance backbone |
| Unity Catalog Storage Credential | 3 (per layer) | Links Access Connector SAMI to Unity Catalog |
| Unity Catalog External Location | 3 (per layer) | Maps each storage account into Unity Catalog |
| Unity Catalog Catalog | 3 (per layer) | Isolated catalog per layer (`bronze_*`, `silver_*`, `gold_*`) |
| Unity Catalog Schema | 3 (per layer) | Default schema per catalog |

## Databricks Asset Bundle Scope

| Resource | Purpose |
|---|---|
| `bronze_layer` job | JDBC ingestion → Bronze managed Delta tables |
| `silver_layer` job | Deduplication / refinement → Silver managed Delta tables |
| `gold_layer` job | Aggregation / curation → Gold managed Delta tables |
| `medallion_orchestrator` job | Chains Bronze → Silver → Gold via `run_job_task`; daily schedule |

## Identity Model

Two modes are supported via `layer_service_principal_mode`:

- **`create`** (default): Terraform creates one Entra ID application + service principal per layer. Requires the deployment SP to have `Application.ReadWrite.All` or `Directory.ReadWrite.All` in the tenant.
- **`existing`**: All three layers share a single pre-existing service principal. Use when the tenant restricts app registration. Requires `existing_layer_sp_client_id` and `existing_layer_sp_object_id`.

## Storage and Security Notes

- Each ADLS Gen2 storage account has `shared_access_key_enabled = true` by default for provider compatibility (AzureRM provider polls blob storage with key auth during create/update). Disable post-deployment once all access is via managed identity.
- Key Vault uses RBAC authorization (`rbac_authorization_enabled = true`) rather than the deprecated legacy access policies.
- Secrets are never exported as Terraform outputs or passed as Databricks job parameters. They are read at runtime by notebooks via `dbutils.secrets.get(scope, key)`.

## Data Model

| Layer | Table | Format |
|---|---|---|
| Bronze | `source_raw` | Delta (append) |
| Silver | `source_refined` | Delta (overwrite) |
| Gold | `source_daily_summary` | Delta (overwrite) |

All tables are **Unity Catalog managed tables** stored under GUID-based paths in ADLS Gen2.

## Naming Convention

All resource names are derived in `locals.tf` from `workload`, `environment`, and `azure_region`:

```
{prefix} = {workload}-{environment}-{region_abbrev}

Resource Group:    rg-{prefix}
Key Vault:         kv-{prefix}
Workspace:         dbw-{prefix}
Storage Account:   sa{workload}{layer_abbrev}{environment}{region_abbrev}  (no hyphens, max 24 chars)
Access Connector:  ac-{prefix}-{layer}
```

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `validate-terraform.yml` | Push / PR | `terraform init -backend=false && terraform validate` |
| `deploy-infrastructure.yml` | Manual dispatch | `terraform apply`, uploads Terraform outputs as artifact |
| `deploy-dab.yml` | Manual dispatch | Downloads outputs artifact, runs `databricks bundle deploy` |

> **State management**: Terraform uses local state in CI/CD. State is ephemeral per workflow run. Delete the resource group before rerunning, or configure a remote Azure Storage backend for persistent state.

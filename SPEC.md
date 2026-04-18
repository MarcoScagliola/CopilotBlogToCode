# Architecture Specification — Secure Medallion on Azure Databricks

## Objective

Implement a least-privilege medallion architecture (Bronze → Silver → Gold) on Azure Databricks where:
- Each layer runs as a dedicated Lakeflow job with its own service principal
- Each layer has isolated ADLS Gen2 storage with RBAC-enforced access
- Secrets are managed in Azure Key Vault
- An orchestrator job chains the three layer jobs in sequence

## Design Decisions

### 1. Identity Isolation
**Decision:** Each layer (Bronze, Silver, Gold) has its own Entra service principal with Storage Blob Data Owner role scoped to its storage account.  
**Rationale:** Limits blast radius—if Bronze code is compromised, it cannot access Silver or Gold data.  
**Flexibility:** If your tenant restricts app registration creation, use `layer_sp_mode=existing` to reuse a pre-created principal.

### 2. Storage Isolation
**Decision:** One ADLS Gen2 storage account (HNS enabled) per layer, each with its own container.  
**Rationale:** Enforces role-based access at the Azure storage level; Databricks enforces additional access at the table level via Unity Catalog.  
**Security:** `shared_access_key_enabled=true` during provisioning (AzureRM provider polling requirement), but can be disabled post-deployment.

### 3. Key Vault Access
**Decision:** Key Vault access policy is tied to `data.azurerm_client_config.current.object_id` (the runtime deployment identity).  
**Rationale:** Ensures Terraform provisioning is independent of hardcoded principal IDs; the running identity always has access.

### 4. Databricks Workspace & Jobs
**Decision:** Single premium workspace, three Lakeflow jobs (bronze, silver, gold) plus an orchestrator.  
**Rationale:** Premium SKU enables Unity Catalog and system table support. Lakeflow jobs provide native scheduling, retries, and alerting.

### 5. State Management (CI/CD Consideration)
**Decision:** Local/ephemeral Terraform state in GitHub Actions runners, with `state_strategy` input for handling pre-existing resources.  
**Rationale:** Simplifies initial deployment without remote backend setup. For production, migrate to Azure Storage backend.  
**Handling Reruns:** Use `state_strategy=recreate_rg` to delete and recreate the resource group on ephemeral reruns.

## Naming Convention

All resource names derive from semantic components in `terraform/locals.tf`:

```
base_name          = "${workload}-${environment}"         # e.g., "blg-dev"
rg_name            = "rg-${base_name}-platform"           # e.g., "rg-blg-dev-platform"
storage_account    = "st${base_name}${layer}"             # e.g., "stblgdevbronze" (24 chars max)
keyvault           = "kv-${base_name}-${random_suffix}"   # e.g., "kv-blg-dev-a1b2c"
workspace          = "dbw-${base_name}"                   # e.g., "dbw-blg-dev"
job_name           = "${layer}-layer-${environment}"      # e.g., "bronze-layer-dev"
principal_name     = "app-${base_name}-${layer}"          # e.g., "app-blg-dev-bronze"
```

## Terraform Outputs

The Terraform stack exports these outputs for downstream DAB deployment and monitoring:

| Output | Purpose |
|---|---|
| `databricks_workspace_url` | Workspace web URL (used by DAB CLI) |
| `databricks_workspace_resource_id` | Azure Resource ID (required for DAB authentication) |
| `layer_principal_client_ids` | Bronze/Silver/Gold service principal client IDs (for job parameter injection) |
| `layer_storage_account_names` | Storage account names per layer (for mounting and credential storage) |
| `key_vault_name` | Key Vault name (for secret scope configuration) |

## Authentication & Secrets

- **Terraform Auth:** Service principal auth via ARM_* environment variables in GitHub Actions.
- **DAB Auth:** Databricks CLI uses workspace resource ID + Azure credentials (same SP as Terraform).
- **Runtime Secrets:** Stored in Azure Key Vault, accessible via Key Vault-backed secret scopes in Databricks.
- **No Hardcoding:** Secrets are never committed to Git or passed plainly in job parameters.

## Security Posture

- **Least Privilege:** Each layer principal has minimal permissions (Storage Blob Data Owner, scoped to its storage account).
- **Encryption:** Storage accounts use TLS 1.2 minimum; all data encrypted at rest via Azure Storage defaults.
- **Audit Trail:** Key Vault access logged; consider enabling diagnostic logs for security monitoring.
- **Zero-Trust Path:** Shared keys can be disabled post-deployment if stricter RBAC-only access is required.

## Post-Deployment Steps

1. **Create Unity Catalog catalogs:** `dev_bronze`, `dev_silver`, `dev_gold`.
2. **Grant layer principals catalog privileges:** Use the client IDs output by Terraform.
3. **Create Key Vault-backed secret scope:** Named per environment (e.g., `kv-dev-scope`).
4. **Replace sample Bronze logic:** Point to actual data source (API, database, etc.).
5. **Monitor system tables:** Use Databricks system tables to track job performance, costs, and data quality per layer.

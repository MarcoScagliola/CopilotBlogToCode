# SPEC — Secure Medallion Architecture on Azure Databricks

## Objective
Implement the secure medallion pattern described in the Microsoft Tech Community blog, using Azure-native identity and storage isolation, Databricks Lakeflow jobs, and Unity Catalog.

## Architecture

Each medallion layer (Bronze, Silver, Gold) is isolated across three axes:
1. **Identity** — dedicated Entra ID service principal per layer, or a single reused principal.
2. **Storage** — dedicated ADLS Gen2 storage account per layer with RBAC-scoped access.
3. **Compute** — dedicated Databricks jobs per layer; an orchestrator job chains them.

## Design Decisions

### Identity mode
- `create`: Terraform provisions one Entra app + service principal per layer.
- `existing`: Terraform accepts a pre-existing service principal and validates it via `azuread_service_principal` data source before assigning roles.
- `principal_type = "ServicePrincipal"` is explicit on all RBAC assignments to prevent `PrincipalTypeNotSupported` errors.

### Key Vault access
- `azurerm_client_config.current.object_id` is used for the access policy, ensuring the runtime deployment identity always has access regardless of what is held in `AZURE_SP_OBJECT_ID`.

### Databricks workspace
- A Premium SKU workspace is provisioned by Terraform.
- `outputs.tf` exports `databricks_workspace_url` and `databricks_workspace_resource_id` from the actual resource (not placeholders).

### Storage security
- `shared_access_key_enabled = false` — all data-plane access uses AAD/RBAC.
- Containers are private.

### DAB deployment bridge
- `deploy_dab.py` maps Terraform output keys to DAB variable names.
- Supports reading outputs from a JSON artifact (split workflow model).

## Naming Convention

| Resource | Pattern |
|---|---|
| Resource group | `rg-<workload>-<environment>-platform` |
| Key Vault | `kv-<workload>-<environment>-<5-char-suffix>` |
| Databricks workspace | `dbw-<workload>-<environment>` |
| Storage account | `st<workload><environment><layer>` (trimmed to 24 chars) |

## Terraform Output Contract

| Output key | Consumed by |
|---|---|
| `databricks_workspace_url` | DAB bridge `workspace_host` |
| `databricks_workspace_resource_id` | DAB bridge `workspace_resource_id` |
| `bronze_sp_application_id` | DAB bridge `bronze_sp_client_id` |
| `silver_sp_application_id` | DAB bridge `silver_sp_client_id` |
| `gold_sp_application_id` | DAB bridge `gold_sp_client_id` |
| `bronze_catalog_name` | DAB bridge `bronze_catalog` |
| `silver_catalog_name` | DAB bridge `silver_catalog` |
| `gold_catalog_name` | DAB bridge `gold_catalog` |
| `secret_scope_name` | DAB bridge `secret_scope` |

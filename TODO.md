# TODO — Values Required Before Deployment

Fill each `<TODO_...>` placeholder before running `terraform apply` or `databricks bundle deploy`.

---

## Terraform (`infra/terraform/terraform.tfvars`)

| Variable | Description | Where to find it |
|---|---|---|
| `azure_subscription_id` | Azure subscription GUID | Azure Portal → Subscriptions |
| `azure_tenant_id` | Entra ID tenant GUID | Azure Portal → Microsoft Entra ID → Overview |
| `databricks_account_id` | Databricks account UUID | https://accounts.azuredatabricks.net → Account Info |
| `databricks_metastore_id` | Unity Catalog metastore UUID | Databricks account console → Data → Metastores |

> `azure_region` defaults to `uksouth`. Override only if needed.  
> `environment` defaults to `prod`. Set to `dev` or `test` for non-production deployments.

---

## Databricks Bundle (`databricks-bundle/databricks.yml` or target override)

| Variable | Description | How to get it |
|---|---|---|
| `<TODO_DATABRICKS_WORKSPACE_URL>` | Workspace URL (e.g. `https://adb-XXXX.azuredatabricks.net`) | Terraform output: `databricks_workspace_url` |
| `<TODO_BRONZE_SP_CLIENT_ID>` | Bronze SP application/client ID | Terraform output: `service_principal_client_ids["bronze"]` |
| `<TODO_SILVER_SP_CLIENT_ID>` | Silver SP application/client ID | Terraform output: `service_principal_client_ids["silver"]` |
| `<TODO_GOLD_SP_CLIENT_ID>` | Gold SP application/client ID | Terraform output: `service_principal_client_ids["gold"]` |
| `<TODO_BRONZE_CATALOG_NAME>` | Unity Catalog name for Bronze | Terraform output: `unity_catalog_names["bronze"]` → e.g. `bronze_catalog` |
| `<TODO_SILVER_CATALOG_NAME>` | Unity Catalog name for Silver | Terraform output: `unity_catalog_names["silver"]` → e.g. `silver_catalog` |
| `<TODO_GOLD_CATALOG_NAME>` | Unity Catalog name for Gold | Terraform output: `unity_catalog_names["gold"]` → e.g. `gold_catalog` |
| `<TODO_ALERT_EMAIL>` | E-mail for job failure notifications | Your ops / data-engineering team address |

---

## Python Source (`databricks-bundle/src/*/main.py`)

### Bronze layer

| Placeholder | Description |
|---|---|
| `<TODO_SOURCE_URL_SECRET_KEY>` | AKV secret key name for the source system JDBC URL / API endpoint |
| `<TODO_SOURCE_USER_SECRET_KEY>` | AKV secret key name for the source system username |
| `<TODO_SOURCE_PASSWORD_SECRET_KEY>` | AKV secret key name for the source system password/token |
| `<TODO_SOURCE_TABLE>` | Source table or resource name to read from |
| `<TODO_TARGET_TABLE>` | Target managed table name in the Bronze catalog |

### Silver layer

| Placeholder | Description |
|---|---|
| `<TODO_BRONZE_SOURCE_TABLE>` | Fully qualified bronze table to read (`bronze_catalog.raw.<table>`) |
| `<TODO_SILVER_TARGET_TABLE>` | Target managed table name in the Silver catalog |
| `<TODO_SILVER_TRANSFORM_LOGIC>` | Data quality / transformation rules specific to your domain |

### Gold layer

| Placeholder | Description |
|---|---|
| `<TODO_SILVER_SOURCE_TABLE>` | Fully qualified silver table to read (`silver_catalog.clean.<table>`) |
| `<TODO_GOLD_TARGET_TABLE>` | Target managed table name in the Gold catalog |
| `<TODO_GOLD_AGGREGATION_LOGIC>` | Business aggregation / metric logic specific to your domain |

---

## Post-Terraform Manual Steps

| Step | Notes |
|---|---|
| Confirm metastore assignment | Verify in Databricks account console → Workspaces that the metastore is assigned |
| AKV diagnostic logging | Add a Monitor diagnostic setting on the Key Vault to a Log Analytics workspace |
| System tables enablement | In Databricks workspace: `ALTER CATALOG system SET OWNER TO ...` and grant access to system catalog |
| SP secret rotation policy | Configure AKV secret rotation for `bronze-sp-client-secret`, `silver-sp-client-secret`, `gold-sp-client-secret` |
| Job schedules | Set `quartz_cron_expression` in `databricks-bundle/resources/jobs.yml` for each layer job and the orchestrator |

---

## Not Required (resolved by defaults)

- `azure_region` → `uksouth` (default; not an unresolved value)
- `environment` → `prod` (default; change as needed)
- `secret_scope_name` → `akv-scope` (default; change if your naming standard differs)

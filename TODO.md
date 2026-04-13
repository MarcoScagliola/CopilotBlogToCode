# TODO – Unresolved Values

This file tracks all placeholder values that must be resolved before running `terraform apply` or `databricks bundle deploy`. Values are grouped by category. Do **not** hardcode any of these in Terraform files or DAB config.

All sensitive values are injected via `TF_VAR_*` environment variables from GitHub repository or environment secrets. See `README.md` for the full secrets table.

---

## 1. Core (Azure Identity)

| Variable | GitHub Secret | TF_VAR Name | Notes |
|---|---|---|---|
| Azure Tenant ID | `AZURE_TENANT_ID` (Environment: BLG2CODEDEV) | `TF_VAR_azure_tenant_id` | Found in Azure Portal → Entra ID → Overview |
| Azure Subscription ID | `AZURE_SUBSCRIPTION_ID` (Environment: BLG2CODEDEV) | `TF_VAR_azure_subscription_id` | Found in Azure Portal → Subscriptions |
| Azure Client ID | `AZURE_CLIENT_ID` (Repository) | `TF_VAR_azure_client_id` | Service Principal used by Terraform and Databricks workspace provider |
| Azure Client Secret | `AZURE_CLIENT_SECRET` (Repository) | `TF_VAR_azure_client_secret` | Client secret for the deployment SP |

> The deployment SP (`AZURE_CLIENT_ID`) requires at minimum: **Contributor** on the subscription (for resource creation), **User Access Administrator** on storage accounts (to assign roles), and **Application Administrator** in Entra ID (to create app registrations).

---

## 2. Databricks Account

| Variable | GitHub Secret | TF_VAR Name | Notes |
|---|---|---|---|
| Databricks Account ID | `DATABRICKS_ACCOUNT_ID` (Repository) | `TF_VAR_databricks_account_id` | Found at accounts.azuredatabricks.net → Settings |
| Databricks Metastore ID | `DATABRICKS_METASTORE_ID` (Repository) | `TF_VAR_databricks_metastore_id` | Unity Catalog metastore must exist before `terraform apply`. Found in Databricks Account Console → Unity Catalog |

> The Unity Catalog metastore must already exist and the deployment SP must be a **Metastore Admin** or have the `CREATE EXTERNAL LOCATION` privilege.

---

## 3. JDBC Source Database

| Variable | GitHub Secret | TF_VAR Name | Notes |
|---|---|---|---|
| JDBC Host | `JDBC_HOST` (Repository) | `TF_VAR_jdbc_host` | Hostname of the source SQL database (e.g. `myserver.database.windows.net`) |
| JDBC Database | `JDBC_DATABASE` (Repository) | `TF_VAR_jdbc_database` | Source database name |
| JDBC User | `JDBC_USER` (Repository) | `TF_VAR_jdbc_user` | SQL login username |
| JDBC Password | `JDBC_PASSWORD` (Repository) | `TF_VAR_jdbc_password` | SQL login password |

> These are stored in Azure Key Vault by Terraform as secrets `jdbc-host`, `jdbc-database`, `jdbc-user`, `jdbc-password`. Jobs read them via the Key Vault-backed secret scope.

---

## 4. DAB Bundle Variables

These are set as bundle variables during `databricks bundle deploy` (passed as `--var` flags or via CI/CD variable injection from Terraform outputs).

| Variable | Source | Notes |
|---|---|---|
| `workspace_host` | Terraform output: `databricks_workspace_url` | Automatically populated in deploy workflow |
| `bronze_catalog` | Terraform output: `bronze_catalog_name` | Automatically populated |
| `silver_catalog` | Terraform output: `silver_catalog_name` | Automatically populated |
| `gold_catalog` | Terraform output: `gold_catalog_name` | Automatically populated |
| `bronze_schema` | Terraform output: `bronze_schema_name` | Automatically populated |
| `silver_schema` | Terraform output: `silver_schema_name` | Automatically populated |
| `gold_schema` | Terraform output: `gold_schema_name` | Automatically populated |
| `bronze_sp_app_id` | Terraform output: `bronze_sp_application_id` | Automatically populated |
| `silver_sp_app_id` | Terraform output: `silver_sp_application_id` | Automatically populated |
| `gold_sp_app_id` | Terraform output: `gold_sp_application_id` | Automatically populated |
| `secret_scope` | Terraform output: `secret_scope_name` | Automatically populated |

---

## 5. Operational Configuration

| Variable | Where to set | Notes |
|---|---|---|
| `source_table_name` | DAB variable or job parameter | The source table to ingest (e.g. `orders`, `customers`). Set in `databricks.yml` or pass as `--var source_table_name=orders` at deploy time |
| `alert_email` | DAB variable or job parameter | Email for job failure notifications. Set in `databricks.yml` or pass at deploy time |
| Cron schedule | `resources/jobs.yml` per job | No cron schedule is set; jobs are triggered manually or via orchestrator. Add `schedule.quartz_cron_expression` to each layer job when ready |

---

## 6. Post-Terraform Manual Steps

After `terraform apply` completes:

1. **Create SP client secrets** in Entra ID for each of the three layer applications (`app-blg-brz-dev`, `app-blg-slv-dev`, `app-blg-gld-dev`).
2. **Store SP secrets in Key Vault** under the names `bronze-sp-secret`, `silver-sp-secret`, `gold-sp-secret`.
3. **Store Tenant ID in Key Vault** under the key `tenant-id` (required by Spark OAuth conf in jobs).
4. **Verify metastore assignment** – confirm the workspace `dbw-blg-dev-uks` shows the correct Unity Catalog metastore in the Databricks Account Console.
5. Populate all GitHub secrets listed in Section 1–3 before triggering the deploy workflow.

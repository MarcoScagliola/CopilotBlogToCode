# TODO — Unresolved Values

## Required before first deployment

| Item | Description | Where to set |
|---|---|---|
| `AZURE_TENANT_ID` | Azure tenant ID for the deployment subscription | GitHub Environment `BLG2CODEDEV` |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | GitHub Environment `BLG2CODEDEV` |
| `AZURE_CLIENT_ID` | Bootstrap service principal client ID | GitHub Environment `BLG2CODEDEV` |
| `AZURE_CLIENT_SECRET` | Bootstrap service principal client secret | GitHub Environment `BLG2CODEDEV` |

## Required after Terraform apply (before bundle deploy)

| Item | Description | Where to set |
|---|---|---|
| `jdbc-host` | Source database hostname | Azure Key Vault |
| `jdbc-database` | Source database name | Azure Key Vault |
| `jdbc-user` | Source database username | Azure Key Vault |
| `jdbc-password` | Source database password | Azure Key Vault |
| Databricks secret scope | AKV-backed scope named by Terraform output `secret_scope_name` | Databricks workspace admin |

## Optional overrides

| Item | Default | Where to override |
|---|---|---|
| `alert_email` | (empty — notifications disabled) | DAB variable or target override |
| `orchestrator_cron` | `0 0 * * * ?` (hourly) | DAB variable or target override |
| `secret_scope_name` | Derived from Key Vault name | Terraform variable |
| `databricks_sku` | `premium` | Terraform variable |
| `azure_region` | `uksouth` | Terraform variable |

## Assumptions

- Unity Catalog metastore is already associated with the Databricks account for the target region.
- The bootstrap service principal has `Contributor` and `User Access Administrator` on the subscription.
- The Databricks workspace must be Unity Catalog-enabled; validation should be confirmed after first `terraform apply`.
- Source system is SQL Server (JDBC driver `com.microsoft.sqlserver.jdbc.SQLServerDriver`); update `src/bronze/main.py` if a different source is used.

# TODO

## Unresolved Required Values
- TODO_AZURE_TENANT_ID -> GitHub Environment secret BLG2CODEDEV/AZURE_TENANT_ID
- TODO_AZURE_SUBSCRIPTION_ID -> GitHub Environment secret BLG2CODEDEV/AZURE_SUBSCRIPTION_ID
- TODO_DATABRICKS_ACCOUNT_ID -> Repository secret DATABRICKS_ACCOUNT_ID
- TODO_DATABRICKS_METASTORE_ID -> Repository secret DATABRICKS_METASTORE_ID
- TODO_DATABRICKS_CLIENT_ID -> Repository secret AZURE_CLIENT_ID (or dedicated Databricks deploy SP)
- TODO_DATABRICKS_CLIENT_SECRET -> Repository secret AZURE_CLIENT_SECRET

## Architecture-specific Secrets
- TODO_JDBC_HOST -> Key Vault secret jdbc-host
- TODO_JDBC_DATABASE -> Key Vault secret jdbc-database
- TODO_JDBC_USER -> Key Vault secret jdbc-user
- TODO_JDBC_PASSWORD -> Key Vault secret jdbc-password

## Follow-up Tasks
- Create terraform.tfvars or workflow tfvars generation with secure injection from secrets.
- Ensure deployment SP has RBAC to create Databricks workspace and role assignments.
- Confirm metastore exists and is available in the target region.
- Validate Databricks cluster policy requirements (if your tenant enforces policies).
- Run terraform plan and terraform apply from GitHub Actions deploy workflow.
- Capture outputs and inject values when deploying Databricks bundle.
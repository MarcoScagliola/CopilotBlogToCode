# TODO

- `TODO_AZURE_TENANT_ID`: store in GitHub Environment `BLG2CODEDEV` as `AZURE_TENANT_ID`.
- `TODO_AZURE_SUBSCRIPTION_ID`: store in GitHub Environment `BLG2CODEDEV` as `AZURE_SUBSCRIPTION_ID`.
- Create the Databricks AKV-backed secret scope named `kv-blg-dev-uks` or set `secret_scope_name` to the preferred value.
- Confirm whether the workspace must use VNet injection, private endpoints, and restricted public access.
- Confirm production schedules and failure notification recipients for Bronze, Silver, Gold, and the orchestrator.
- Confirm whether Databricks cluster policies must be enforced in this repo baseline.
- Validate the exact JDBC driver and source query for the Bronze ingestion notebook against the target source system.
- Review Unity Catalog grants after first deploy to ensure each layer principal has only the intended catalog and external-location permissions.

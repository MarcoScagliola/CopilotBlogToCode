# TODO.md

Fill these unresolved values before deploy.

Region is fixed by skill default to `uksouth` and is not listed as unresolved.

## Global
- `subscription_id`: `<TODO_SUBSCRIPTION_ID>`
- `tenant_id`: `<TODO_TENANT_ID>`
- `resource_group_name`: `<TODO_RESOURCE_GROUP_NAME>`
- `environment`: `<TODO_ENVIRONMENT>`

## Databricks
- `databricks_workspace_url`: `<TODO_DATABRICKS_WORKSPACE_URL>`
- `databricks_account_id`: `<TODO_DATABRICKS_ACCOUNT_ID>`
- `unity_catalog_metastore_id` (if assignment/validation is needed in your environment): `<TODO_METASTORE_ID>`

## Azure Networking (optional, only if `enable_networking = true`)
- `vnet_name`: `<TODO_VNET_NAME>`
- `vnet_address_space`: `<TODO_VNET_CIDR>`
- `public_subnet_name`: `<TODO_PUBLIC_SUBNET_NAME>`
- `public_subnet_address_prefixes`: `<TODO_PUBLIC_SUBNET_CIDR_LIST>`
- `private_subnet_name`: `<TODO_PRIVATE_SUBNET_NAME>`
- `private_subnet_address_prefixes`: `<TODO_PRIVATE_SUBNET_CIDR_LIST>`
- `nsg_name`: `<TODO_NSG_NAME>`

## Layer-specific Names (do not invent)
- `layer_storage_account_names.bronze`: `<TODO_STORAGE_ACCOUNT_BRONZE>`
- `layer_storage_account_names.silver`: `<TODO_STORAGE_ACCOUNT_SILVER>`
- `layer_storage_account_names.gold`: `<TODO_STORAGE_ACCOUNT_GOLD>`

- `layer_managed_identity_names.bronze`: `<TODO_UAMI_BRONZE>`
- `layer_managed_identity_names.silver`: `<TODO_UAMI_SILVER>`
- `layer_managed_identity_names.gold`: `<TODO_UAMI_GOLD>`

- `layer_access_connector_names.bronze`: `<TODO_ACCESS_CONNECTOR_BRONZE>`
- `layer_access_connector_names.silver`: `<TODO_ACCESS_CONNECTOR_SILVER>`
- `layer_access_connector_names.gold`: `<TODO_ACCESS_CONNECTOR_GOLD>`

- `layer_service_principal_display_names.bronze`: `<TODO_SP_BRONZE_DISPLAY_NAME>`
- `layer_service_principal_display_names.silver`: `<TODO_SP_SILVER_DISPLAY_NAME>`
- `layer_service_principal_display_names.gold`: `<TODO_SP_GOLD_DISPLAY_NAME>`

- `layer_storage_credential_names.bronze`: `<TODO_STORAGE_CREDENTIAL_BRONZE>`
- `layer_storage_credential_names.silver`: `<TODO_STORAGE_CREDENTIAL_SILVER>`
- `layer_storage_credential_names.gold`: `<TODO_STORAGE_CREDENTIAL_GOLD>`

- `layer_external_location_names.bronze`: `<TODO_EXTERNAL_LOCATION_BRONZE>`
- `layer_external_location_names.silver`: `<TODO_EXTERNAL_LOCATION_SILVER>`
- `layer_external_location_names.gold`: `<TODO_EXTERNAL_LOCATION_GOLD>`

- `layer_catalog_names.bronze`: `<TODO_CATALOG_BRONZE>`
- `layer_catalog_names.silver`: `<TODO_CATALOG_SILVER>`
- `layer_catalog_names.gold`: `<TODO_CATALOG_GOLD>`

- `layer_schema_names.bronze`: `<TODO_SCHEMA_BRONZE>`
- `layer_schema_names.silver`: `<TODO_SCHEMA_SILVER>`
- `layer_schema_names.gold`: `<TODO_SCHEMA_GOLD>`

## Security / Secrets
- `key_vault_name`: `<TODO_KEY_VAULT_NAME>`
- `secret_scope_name`: `<TODO_DATABRICKS_SECRET_SCOPE_NAME>`

## Bundle Runtime
- `notification_email`: `<TODO_NOTIFICATION_EMAIL>`
- `job_schedule_quartz`: `<TODO_QUARTZ_CRON>`
- `job_schedule_timezone`: `<TODO_TIMEZONE>`
- `bronze_service_principal_application_id`: `<TODO_BRONZE_SP_APP_ID>`
- `silver_service_principal_application_id`: `<TODO_SILVER_SP_APP_ID>`
- `gold_service_principal_application_id`: `<TODO_GOLD_SP_APP_ID>`
- `bronze_runtime`: `<TODO_BRONZE_RUNTIME>`
- `silver_runtime`: `<TODO_SILVER_RUNTIME>`
- `gold_runtime`: `<TODO_GOLD_RUNTIME>`
- `bronze_node_type_id`: `<TODO_BRONZE_NODE_TYPE_ID>`
- `silver_node_type_id`: `<TODO_SILVER_NODE_TYPE_ID>`
- `gold_node_type_id`: `<TODO_GOLD_NODE_TYPE_ID>`

# SPEC

## Source
Secure Medallion Architecture Pattern on Azure Databricks (Part I):
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture Summary
This implementation enforces least privilege by splitting the Medallion pipeline into independent Bronze, Silver, and Gold jobs. Each layer has dedicated identity, storage access path, and Unity Catalog boundaries to minimize blast radius.

## Infrastructure Scope
- 1 resource group
- 1 Azure Databricks Premium workspace
- 3 ADLS Gen2 storage accounts (bronze/silver/gold)
- 3 Databricks Access Connectors (one per layer)
- 1 Azure Key Vault
- 1 Unity Catalog metastore assignment
- 3 storage credentials + 3 external locations + 3 catalogs + 3 schemas
- Optional per-layer Entra applications/service principals, or reuse of existing identity

## Security and Compatibility Decisions
- `layer_service_principal_mode` supports `create` and `existing`.
- `storage_shared_key_enabled` defaults to `true` for provider compatibility during provisioning.
- `rbac_authorization_enabled` is used for Key Vault.
- Secrets are fetched at runtime via AKV-backed Databricks secret scope.

## Data Flow
- Bronze: JDBC ingestion into `source_raw`
- Silver: deduplicate/refine into `source_refined`
- Gold: aggregate into `source_daily_summary`

## CI/CD Workflows
- `validate-terraform.yml` validates Terraform syntax.
- `deploy-infrastructure.yml` applies Terraform and publishes outputs.
- `deploy-dab.yml` deploys the Databricks bundle using infra outputs.

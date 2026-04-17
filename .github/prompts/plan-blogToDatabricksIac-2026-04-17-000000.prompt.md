# Execution Plan — Blog to Databricks IaC
# Date: 2026-04-17

## Source
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Active Run Context
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET

## Architecture Summary
Generate a secure Azure Databricks medallion architecture with Bronze, Silver, and Gold isolation. Provision Azure Databricks, per-layer storage accounts, Databricks Access Connectors, Key Vault, Unity Catalog objects, and Databricks Lakeflow Jobs. Support restrictive tenants by allowing reuse of an existing service principal instead of forcing Entra app registration creation.

## Generation Notes
- Use Terraform for Azure and Databricks-adjacent infrastructure
- Use Databricks Asset Bundle for jobs and Python entrypoints
- Keep storage account defaults deployment-safe for current AzureRM provider behavior
- Use current non-deprecated AzureRM properties
- Generate workflows for validate, infra deploy, and DAB deploy
- Document unresolved secrets and post-deploy steps in TODO.md and README.md

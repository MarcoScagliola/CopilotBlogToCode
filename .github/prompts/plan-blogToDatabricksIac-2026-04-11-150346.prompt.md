# Execution Plan — Blog to Databricks IaC
Date: 2026-04-11-150346

## Source
URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Title: Secure Medallion Architecture Pattern on Azure Databricks (Part I)

## Run Inputs
- workload: blg
- environment: dev
- azure_region: uksouth

## Architecture Summary
Medallion Architecture (Bronze / Silver / Gold) on Azure Databricks with Lakeflow Jobs.
Each layer runs under a dedicated Entra ID service principal with least-privilege access.
Per-layer ADLS Gen2 storage accounts, Access Connectors, Unity Catalog catalogs/schemas,
and dedicated job clusters enforce strict separation of duties.
Azure Key Vault stores secrets; AKV-backed secret scopes are used at runtime.

## Deployment Model
- Terraform: resource group, Databricks workspace, ADLS Gen2 accounts, Access Connectors,
  Entra apps/SPs, Key Vault, UC storage credentials, external locations, catalogs, schemas, grants
- DAB: 4 Lakeflow jobs (bronze, silver, gold, orchestrator), job clusters, Python entrypoints

## Reference Files Applied
- references/azure/cloud-deployment.md
- references/azure/core-variables.md
- references/azure/region-policy.md
- references/azure/naming-conventions.md

## Unresolved (TODO)
- TODO_AZURE_TENANT_ID
- TODO_AZURE_SUBSCRIPTION_ID
- TODO_DATABRICKS_ACCOUNT_ID
- TODO_METASTORE_ID
- TODO_ALERT_EMAIL
- JDBC source connection details (host, database, user, password)

## Output Files
- SPEC.md
- TODO.md
- infra/terraform/versions.tf
- infra/terraform/providers.tf
- infra/terraform/variables.tf
- infra/terraform/locals.tf
- infra/terraform/main.tf
- infra/terraform/outputs.tf
- databricks-bundle/databricks.yml
- databricks-bundle/resources/jobs.yml
- databricks-bundle/src/bronze/main.py
- databricks-bundle/src/silver/main.py
- databricks-bundle/src/gold/main.py
- databricks-bundle/src/orchestrator/main.py
- README.md (updated)

# Execution Plan — Blog to Databricks IaC
# Date: 2026-04-16

## Source
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Run Parameters
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET

## Architecture Summary
Secure Medallion Architecture on Azure Databricks. Bronze, Silver, Gold each run as isolated Lakeflow Jobs executed by dedicated Entra ID service principals with least-privilege access. Per-layer ADLS Gen2 storage accounts, Access Connectors (system-assigned managed identities), Unity Catalog catalogs/schemas, and a shared Azure Key Vault for secrets.

## Generated Artifacts
1. infra/terraform/ — Terraform for Azure + Databricks infrastructure
2. databricks-bundle/ — DAB with bronze/silver/gold/orchestrator jobs
3. .github/workflows/ — validate-terraform, deploy-infrastructure, deploy-dab
4. SPEC.md, TODO.md, README.md

## Key Design Decisions
- One resource group for all Azure resources
- One Databricks workspace (Premium SKU, Unity Catalog)
- Three ADLS Gen2 storage accounts (one per layer, HNS enabled)
- Three Databricks Access Connectors with system-assigned managed identities
- Three Entra app registrations + service principals (bronze/silver/gold) created by Terraform
- One Azure Key Vault with RBAC authorization
- Layer SPs get Key Vault Secrets User on the Key Vault
- Access connectors get Storage Blob Data Contributor on own layer, Storage Blob Data Reader on upstream
- Unity Catalog: storage credential, external location, catalog, schema per layer
- DAB: each job runs as its layer SP; orchestrator job chains all three
- Secrets (JDBC) stored in AKV, read at runtime via AKV-backed secret scope

# Secure Medallion Architecture Specification

## Source
- Blog: Secure Medallion Architecture Pattern on Azure Databricks (Part I)
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture Summary
- Pattern: security-first Medallion architecture with isolated Bronze, Silver, and Gold layers.
- Execution model: one Lakeflow job per layer plus an orchestrator job.
- Governance model: Unity Catalog catalogs and schemas separated by layer.
- Secret model: runtime secret retrieval from an Azure Key Vault-backed Databricks secret scope.

## Azure Components
- Azure Databricks workspace.
- Azure Data Lake Storage Gen2 storage account per layer.
- Databricks Access Connector per layer.
- Azure Key Vault for runtime secrets.
- Microsoft Entra service principals for deployment and layer execution.

## Security Decisions
- Least privilege enforced with per-layer identities.
- Separate storage and compute blast-radius boundaries by layer.
- No secret values in code, Git, workflow inputs, or job parameters.
- Key Vault soft-delete recovery is handled in workflow retry logic.

## Default Inputs
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- layer_sp_mode: create

## Runtime Flow
1. setup_job provisions Medallion catalogs and schemas.
2. bronze_job lands seed event data into Bronze.
3. silver_job transforms and deduplicates Bronze into Silver.
4. gold_job aggregates Silver into Gold.
5. smoke_test_job validates end-to-end data presence.

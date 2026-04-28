# Secure Medallion Architecture Specification

## Source
- Blog: Secure Medallion Architecture Pattern on Azure Databricks (Part I)
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture Summary
- Pattern: Medallion architecture with isolated Bronze, Silver, and Gold layers.
- Security model: least privilege with per-layer execution identities and scoped access.
- Orchestration: one job per layer plus one orchestrator job.
- Governance plane: Unity Catalog with per-layer catalog and schema boundaries.
- Secret handling: runtime retrieval through Azure Key Vault-backed Databricks secret scope.

## Azure Components
- Azure Databricks workspace (Unity Catalog enabled).
- ADLS Gen2 storage accounts: one per layer.
- Databricks Access Connectors: one per layer.
- Azure Key Vault for runtime secrets.
- Microsoft Entra service principals for layer execution.

## Baseline Defaults
- Workload: blg
- Environment: dev
- Region: uksouth
- GitHub environment: BLG2CODEDEV
- Layer principal mode: create (supports existing mode)

## Data Flow
1. setup_job creates catalogs and schemas.
2. bronze_job ingests seed events into Bronze.
3. silver_job standardizes and deduplicates into Silver.
4. gold_job computes aggregate facts into Gold.
5. smoke_test_job validates minimum data presence.

## Key Security Choices
- Separate storage, compute, and principal boundaries per layer.
- No secret values in code, workflow inputs, or job parameters.
- RBAC assignments restricted to required scopes.
- Recovery-safe workflow behavior for Key Vault soft-delete cases.

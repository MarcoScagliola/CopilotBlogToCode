# Blog to Databricks IaC Execution Record

## Resolved inputs

- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID

## Source article

- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch timestamp: 2026-05-14

## SPEC summary

- [SPEC.md](../../SPEC.md) captures the source article as a security-first medallion architecture on Azure Databricks.
- The generated baseline uses separate Bronze, Silver, and Gold storage accounts, a Key Vault, a Databricks workspace, access connectors, and layer service principals.
- The bundle uses synthetic managed tables so the jobs can run end-to-end even though the article does not name real business datasets or exact target tables.
- Major unresolved items were moved into [TODO.md](../../TODO.md), including runtime secret keys, networking posture, and the final business table contracts.
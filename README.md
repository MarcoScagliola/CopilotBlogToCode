# Secure Medallion On Azure Databricks

This repository implements the secure Medallion pattern described in the article Secure Medallion Architecture Pattern on Azure Databricks (Part I).

- Source article: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Workload baseline: blg
- Environment baseline: dev
- Region baseline: uksouth
- GitHub environment baseline: BLG2CODEDEV

## What Gets Deployed

- Azure infrastructure with Terraform under `infra/terraform`.
- Databricks Asset Bundle under `databricks-bundle`.
- Three generated GitHub workflows:
	- `.github/workflows/validate-terraform.yml`
	- `.github/workflows/deploy-infrastructure.yml`
	- `.github/workflows/deploy-dab.yml`

The architecture follows Bronze, Silver, and Gold isolation with one principal, one storage account, one access connector, and one job cluster family per layer.

## Repository Layout

- `infra/terraform`: Azure resources and identity/RBAC plumbing.
- `databricks-bundle/databricks.yml`: bundle variables and targets.
- `databricks-bundle/resources/jobs.yml`: generated Lakeflow job topology.
- `databricks-bundle/src/*/main.py`: setup, Bronze, Silver, Gold, smoke-test entrypoints.
- `SPEC.md`: extracted architecture facts and unresolved article gaps.
- `TODO.md`: unresolved decisions and manual actions.

## Required Secrets

Set these in GitHub Environment BLG2CODEDEV:

- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET
- AZURE_SP_OBJECT_ID

## Deployment Flow

1. Run Validate Terraform workflow.
2. Run Deploy Infrastructure workflow.
3. Run Deploy DAB workflow using the infrastructure run artifact.
4. Execute the orchestrator job in Databricks.

## Notes

- This baseline intentionally keeps unresolved architecture choices in TODO.md.
- No Databricks PAT is required by the generated deploy bridge; Azure service-principal auth is used.
- Runtime secrets are expected in Azure Key Vault and consumed via an AKV-backed scope.

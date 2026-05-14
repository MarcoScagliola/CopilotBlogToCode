# Secure Medallion Architecture on Azure Databricks

This repository implements the architecture described in [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268).

## What this repository deploys

The generated solution deploys a secure medallion data platform with strong layer isolation:

- Bronze, Silver, and Gold processing layers.
- Per-layer storage accounts.
- Per-layer execution identities (create mode or existing mode).
- Databricks workspace and access connectors.
- Key Vault for runtime secret retrieval.
- Lakeflow-style Databricks jobs and an orchestrator job in a Databricks Asset Bundle.

Infrastructure is under `infra/terraform/`. Workload deployment assets are under `databricks-bundle/`. CI/CD workflows are under `.github/workflows/`.

## Inputs used for this generation run

- Workload: `blg`
- Environment: `dev`
- Region: `uksouth`
- Layer SP mode: `create`
- GitHub Environment: `BLG2CODEDEV`

## Required GitHub environment secrets

Populate these in GitHub Environment `BLG2CODEDEV`:

- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`

Optional (used when dispatching infrastructure workflow with `layer_sp_mode=existing`):

- `EXISTING_LAYER_SP_CLIENT_ID`
- `EXISTING_LAYER_SP_OBJECT_ID`

## Workflow responsibilities

- `validate-terraform.yml`: static Terraform validation (`init -backend=false`, `validate`).
- `deploy-infrastructure.yml`: Terraform apply and output artifact publishing.
- `deploy-dab.yml`: deploys Databricks bundle using infrastructure outputs and Azure SP auth.

## Deployment flow

1. Run `Validate Terraform`.
2. Run `Deploy Infrastructure` with desired dispatch inputs.
3. Ensure post-infra tasks in `TODO.md` are completed (secret scope + runtime secrets).
4. Run `Deploy DAB`.
5. Execute orchestrator/smoke tests in Databricks.

## Notes

- This repository intentionally treats unresolved environment-specific values as operator decisions tracked in `TODO.md`.
- Security and governance assumptions are documented in `SPEC.md`.

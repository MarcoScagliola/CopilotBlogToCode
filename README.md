# Secure Medallion Architecture on Azure Databricks

This repository implements the Azure Databricks architecture pattern described in [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268). The detailed architecture interpretation is documented in [SPEC.md](SPEC.md), while operationally deferred items are tracked in [TODO.md](TODO.md).

## What this repository deploys

The generated baseline deploys:
- Azure infrastructure for a secure medallion platform in `uksouth` with workload `blg` and environment `dev`.
- A Databricks Asset Bundle with setup, bronze, silver, gold, smoke-test, and orchestrator jobs.
- CI/CD workflows to validate Terraform, deploy infrastructure, and deploy the Databricks bundle.

Terraform resources are defined in [infra/terraform/](infra/terraform/). Databricks jobs and entrypoints are defined in [databricks-bundle/](databricks-bundle/).

## Repository layout

```
.
├── infra/terraform/              Infrastructure resources and outputs
├── databricks-bundle/            Databricks Asset Bundle and entrypoints
├── .github/workflows/            Validation and deployment workflows
├── SPEC.md                       Architecture extraction from the source article
├── TODO.md                       Unresolved and deferred operator tasks
└── README.md                     This runbook
```

## Required GitHub environment

Use GitHub Environment: `BLG2CODEDEV`

Required secrets/variables (secret preferred, vars fallback supported by workflows):
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`

Optional when using existing layer principal mode:
- `EXISTING_LAYER_SP_CLIENT_ID`
- `EXISTING_LAYER_SP_OBJECT_ID`

## Workflow order

1. Run [validate-terraform.yml](.github/workflows/validate-terraform.yml) to check Terraform syntax.
2. Run [deploy-infrastructure.yml](.github/workflows/deploy-infrastructure.yml) with desired dispatch inputs.
3. Run [deploy-dab.yml](.github/workflows/deploy-dab.yml) using the infrastructure run ID, or allow auto-trigger after infra succeeds.

## Notes

- This baseline intentionally keeps unresolved environment-specific decisions in [TODO.md](TODO.md) instead of inventing values not provided by the article.
- Sensitive runtime values (API keys, database passwords, tokens) must be stored in Azure Key Vault and accessed via a Databricks Key Vault-backed secret scope.

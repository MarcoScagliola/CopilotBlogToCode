# Secure Medallion Architecture on Azure Databricks (Part I)

This repository was generated from the Microsoft article below and prepared for automated deployment with Terraform and Databricks Asset Bundles.

- Source: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Workload: blg
- Environment: dev
- Region: uksouth
- Layer principal mode: create
- GitHub Environment: BLG2CODEDEV

## Generated Artifacts

- Terraform infrastructure in infra/terraform
- Databricks bundle in databricks-bundle
- GitHub workflows in .github/workflows
- Architecture notes in SPEC.md
- Operator checklist in TODO.md

## Workflows

- validate-terraform.yml: static Terraform validation.
- deploy-infrastructure.yml: provisions Azure infrastructure and publishes Terraform outputs artifact.
- deploy-dab.yml: deploys Databricks bundle using outputs from infrastructure run.

## Notes

- This baseline uses local Terraform state in CI and supports recovery and fallback logic in the deploy workflow.
- Runtime secret values are intentionally not stored in repository files and must be added post-deploy.

# Secure Medallion on Azure Databricks

This repository contains a generated baseline for the article Secure Medallion Architecture Pattern on Azure Databricks (Part I).

## Design summary

- Medallion flow is modeled as setup, bronze, silver, gold, and orchestrator jobs.
- Security boundary is layered: per-layer storage, per-layer access connector, and per-layer principal outputs.
- Runtime secrets are externalized to Azure Key Vault and consumed from Databricks secret scope.
- Terraform provisions Azure resources; Databricks Asset Bundle deploys runtime jobs.

## Generated artifacts

- Terraform: infra/terraform
- Databricks bundle: databricks-bundle
- Workflow generators: .github/skills/blog-to-databricks-iac/scripts/azure
- Generated workflows: .github/workflows
- Architecture analysis: SPEC.md
- Operator actions: TODO.md

## Resolved input values for this run

- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV

## Deployment flow

1. Run validate workflow to check Terraform syntax and configuration.
2. Run infrastructure workflow to provision Azure resources and emit terraform outputs artifact.
3. Run DAB workflow to deploy jobs using terraform outputs artifact.
4. Execute orchestrator job for functional verification.

## Assumptions

- Existing Azure subscription and tenant credentials are provided via GitHub environment secrets.
- Article did not provide concrete source datasets, schedule SLAs, or full network topology.
- Generated defaults are safe scaffolding and require operator completion per TODO.md.

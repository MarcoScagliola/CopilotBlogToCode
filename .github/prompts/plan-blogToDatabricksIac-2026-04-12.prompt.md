# Execution Plan — Blog to Databricks IaC
Date: 2026-04-12

## Source
URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Title: Secure Medallion Architecture Pattern on Azure Databricks (Part I)

## Inputs
- workload: blg
- environment: dev
- azure_region: uksouth

## Planned Outputs
- SPEC.md
- TODO.md
- infra/terraform/{versions.tf,providers.tf,variables.tf,locals.tf,main.tf,outputs.tf}
- databricks-bundle/databricks.yml
- databricks-bundle/resources/jobs.yml
- databricks-bundle/src/{bronze,silver,gold,orchestrator}/main.py
- README.md
- .github/workflows/validate-terraform.yml
- .github/workflows/deploy.yml

## Generation Strategy
1. Build security-first medallion infrastructure in Terraform with strict Terraform/DAB boundary.
2. Generate DAB jobs and per-layer entrypoints with least-privilege run identities.
3. Keep unresolved sensitive/runtime values in TODO.md only.
4. Produce deployment instructions with Terraform-first then DAB deployment.

# SPEC

## Goal
Implement a secure Medallion architecture baseline inspired by the referenced blog post:
- Layered data pipeline: Bronze, Silver, Gold
- Separate job per layer plus orchestrator
- Dedicated storage paths per layer
- Identity isolation with least privilege (create or reuse mode)
- CI/CD split between infrastructure and DAB deployment

## Scope
This repository includes:
- Terraform infrastructure in infra/terraform
- Databricks Asset Bundle in databricks-bundle
- GitHub Actions workflows in .github/workflows

## Terraform design
- Creates resource group, key vault, and one ADLS Gen2 account per medallion layer
- Supports identity mode:
  - create: create dedicated Entra applications/service principals per layer
  - existing: reuse provided principal client/object IDs
- Assigns Storage Blob Data Owner on each layer storage account to the layer principal
- Emits outputs required by deploy_dab.py bridge script

## DAB design
- Bundle targets: dev and prd
- Jobs:
  - bronze_job
  - silver_job
  - gold_job
  - orchestrator_job (run_job_task chain)

## CI/CD design
- validate-terraform.yml: init/validate checks
- deploy-infrastructure.yml: terraform apply + output artifacts
- deploy-dab.yml: consumes infra artifacts and deploys bundle

## Non-goals
- Full production hardening (network isolation, private endpoints, CMK)
- Complete Unity Catalog object provisioning
- Environment-specific catalog/table bootstrap automation

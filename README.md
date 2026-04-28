## Secure Medallion Architecture on Azure Databricks

This repository implements the architecture from:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

The solution deploys a security-first Medallion pattern with strict layer isolation:
- Bronze, Silver, and Gold each use separate storage, identities, and compute boundaries.
- Unity Catalog catalogs and schemas are separated by layer.
- Lakeflow jobs are split by layer and orchestrated in sequence.
- Runtime secrets are read from an Azure Key Vault-backed Databricks secret scope.

## Repo Structure

- infra/terraform/: Azure infrastructure provisioning.
- databricks-bundle/: Databricks Asset Bundle jobs and code.
- .github/workflows/: CI/CD for validation and deployment.

## Prerequisites

- Python 3.10+
- Terraform 1.8+
- Azure CLI authenticated to the target tenant and subscription
- Databricks CLI for bundle deployment
- GitHub Environment BLG2CODEDEV configured with:
  - AZURE_TENANT_ID
  - AZURE_SUBSCRIPTION_ID
  - AZURE_CLIENT_ID
  - AZURE_CLIENT_SECRET
  - AZURE_SP_OBJECT_ID
  - optional for existing-mode: EXISTING_LAYER_SP_CLIENT_ID, EXISTING_LAYER_SP_OBJECT_ID

## Generated Workflows

- validate-terraform.yml: Terraform static validation.
- deploy-infrastructure.yml: Deploy Azure infrastructure and publish outputs.
- deploy-dab.yml: Deploy Databricks bundle using infrastructure outputs.

## Local Validation

```powershell
Get-ChildItem .github/skills/blog-to-databricks-iac/scripts/azure -Filter *.py | ForEach-Object { python -m py_compile $_.FullName }
Get-ChildItem databricks-bundle/src -Recurse -Filter main.py | ForEach-Object { python -m py_compile $_.FullName }
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --contract-only
```

## Deployment Flow

1. Run Validate Terraform.
2. Run Deploy Infrastructure with defaults:
   - workload: blg
   - environment: dev
   - azure_region: uksouth
   - layer_sp_mode: create
   - key_vault_recovery_mode: auto
3. Complete post-infrastructure items in TODO.md.
4. Run Deploy DAB using the infrastructure run id.
5. Trigger orchestrator_job in Databricks to execute setup, bronze, silver, gold, and smoke test.

## Runtime Jobs

- setup_job: creates Unity Catalog catalogs and schemas.
- bronze_job: ingests seed events and writes Bronze data.
- silver_job: deduplicates and standardizes Bronze data.
- gold_job: aggregates Silver data into Gold facts.
- smoke_test_job: verifies minimum rows exist across layers.
- orchestrator_job: runs all jobs in dependency order.

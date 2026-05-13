# Blog to Databricks IaC Execution Record

## Resolved Inputs

- workload: blg
- environment: tst
- azure_region: uksouth
- layer_sp_mode: existing
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID
- existing_layer_sp_client_id_secret_name: EXISTING_LAYER_SP_CLIENT_ID
- existing_layer_sp_object_id_secret_name: EXISTING_LAYER_SP_OBJECT_ID

## Source

- Blog URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch timestamp: 2026-05-13-072548
- SPEC path: SPEC.md

## Architecture Summary

The generated baseline implements a secure medallion deployment pattern on Azure Databricks with per-layer separation for identities, storage, and compute. All layers share a single existing Entra service principal (no new principals created). It deploys Azure infrastructure using Terraform and runtime jobs using a Databricks Asset Bundle.

## Generated Artifacts

- .github/workflows/validate-terraform.yml
- .github/workflows/deploy-infrastructure.yml
- .github/workflows/deploy-dab.yml
- databricks-bundle/resources/jobs.yml
- databricks-bundle/databricks.yml
- databricks-bundle/src/setup/main.py
- databricks-bundle/src/bronze/main.py
- databricks-bundle/src/silver/main.py
- databricks-bundle/src/gold/main.py
- databricks-bundle/src/smoke_test/main.py
- infra/terraform/versions.tf
- infra/terraform/providers.tf
- infra/terraform/variables.tf
- infra/terraform/locals.tf
- infra/terraform/main.tf
- infra/terraform/outputs.tf
- SPEC.md
- TODO.md
- README.md

## Validation Results (Pending)

Final validation checks will be run to confirm:
- Python compile of entrypoints
- Terraform syntax validation
- YAML parsing of workflows and bundle
- Parity checks for deploy bridge compatibility

## Deferred Items

Unresolved items are tracked in TODO.md across these sections:
- Pre-deployment
- Deployment-time inputs
- Post-infrastructure
- Post-DAB
- Architectural decisions deferred

## Key Differences from create Mode

- No azuread_application or azuread_service_principal resources created
- All layers reference the existing principal via var.existing_layer_sp_* variables
- Deploy workflow requires EXISTING_LAYER_SP_CLIENT_ID and EXISTING_LAYER_SP_OBJECT_ID secrets
- Terraform locals.tf uses existing principal IDs directly instead of creating new ones

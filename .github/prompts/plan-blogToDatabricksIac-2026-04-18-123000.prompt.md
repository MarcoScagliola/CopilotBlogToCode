Execution plan for implementing the Secure Medallion Architecture pattern on Azure Databricks from the source blog.

1. Resolve run context defaults:
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID
- existing_layer_sp_client_id_secret_name: EXISTING_LAYER_SP_CLIENT_ID
- existing_layer_sp_object_id_secret_name: EXISTING_LAYER_SP_OBJECT_ID

2. Fetch and parse source blog content.
3. Regenerate workflows:
- .github/workflows/validate-terraform.yml
- .github/workflows/deploy-infrastructure.yml
- .github/workflows/deploy-dab.yml
4. Ensure Terraform infrastructure code in infra/terraform satisfies medallion requirements and identity-mode flexibility.
5. Ensure Databricks Asset Bundle jobs and scripts reflect bronze/silver/gold plus orchestrator.
6. Generate README.md and TODO.md from templates with placeholder substitution.
7. Validate outputs:
- Python compile checks
- terraform init -backend=false
- terraform validate
- YAML parse checks for workflows and DAB files
8. Report completion and next deployment steps.

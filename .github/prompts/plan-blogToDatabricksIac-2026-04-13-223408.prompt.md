Execution plan for Secure Medallion Architecture generation.

Run context:
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID

Plan:
1. Fetch and parse architecture details from the provided blog URL.
2. Generate/refresh workflow files:
   - .github/workflows/validate-terraform.yml
   - .github/workflows/deploy.yml
   using github environment and secret names from run context.
3. Generate Terraform in infra/terraform:
   - versions.tf, providers.tf, variables.tf, locals.tf, main.tf, outputs.tf
   with medallion isolation (bronze/silver/gold), Key Vault-backed secrets, and Unity Catalog resources.
4. Generate Databricks Asset Bundle in databricks-bundle:
   - databricks.yml
   - resources/jobs.yml
   - src/bronze/main.py
   - src/silver/main.py
   - src/gold/main.py
   - src/orchestrator/main.py
5. Generate docs:
   - SPEC.md
   - TODO.md
   - README.md
6. Validate generation output presence and summarize next deployment steps.

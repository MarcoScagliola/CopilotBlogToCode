Execution plan for Secure Medallion Architecture generation.

Run context:
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID

Blog: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Plan:
1. Generate/refresh workflow files (validate-terraform.yml, deploy.yml)
2. Generate Terraform: versions.tf, providers.tf, variables.tf, locals.tf, main.tf, outputs.tf
3. Generate DAB: databricks.yml, jobs.yml, src/bronze/main.py, src/silver/main.py, src/gold/main.py, src/orchestrator/main.py
4. Generate docs: SPEC.md, TODO.md, README.md
5. Run terraform fmt + init -backend=false + validate

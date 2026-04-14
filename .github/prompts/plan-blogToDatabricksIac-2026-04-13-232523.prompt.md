Execution plan for Secure Medallion Architecture generation.

Run context:
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID

Blog URL:
- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Plan:
1. Generate workflow files:
   - .github/workflows/validate-terraform.yml
   - .github/workflows/deploy-infrastructure.yml
   - .github/workflows/deploy-dab.yml
2. Generate Terraform files under infra/terraform.
3. Generate DAB files under databricks-bundle.
4. Generate docs: SPEC.md, TODO.md, README.md.
5. Run Terraform static validation: fmt + init -backend=false + validate.

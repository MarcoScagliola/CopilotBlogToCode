Execution plan for implementing the Secure Medallion Architecture pattern on Azure Databricks from the source blog.

1. Resolve run context defaults (workload=blg, environment=dev, azure_region=uksouth, github_environment=BLG2CODEDEV and AZURE_* secret names).
2. Fetch and parse source blog content.
3. Regenerate workflows (validate/deploy-infrastructure/deploy-dab).
4. Rebuild Terraform stack in infra/terraform (workspace, storage, key vault, identity mode, outputs bridge).
5. Rebuild Databricks bundle (jobs and bronze/silver/gold scripts).
6. Generate README and TODO from templates with placeholder substitution.
7. Add functional-test run instructions and blockers to TODO if environment execution is unavailable.
8. Run mandatory validation checks:
   - Python compile checks
   - terraform init -backend=false
   - terraform validate
   - YAML parse checks
9. Report outcomes and next deployment steps.

Execution Plan - Blog to Databricks IaC (2026-04-20)

Source article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Run context:
- workload: blg
- environment: dev
- azure_region: eastus2
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID
- existing_layer_sp_client_id_secret_name: EXISTING_LAYER_SP_CLIENT_ID
- existing_layer_sp_object_id_secret_name: EXISTING_LAYER_SP_OBJECT_ID

Execution steps:
1. Regenerate GitHub workflows for terraform validation, infrastructure deployment, and DAB deployment.
2. Recreate Terraform files under infra/terraform for secure medallion architecture.
3. Recreate Databricks Asset Bundle files under databricks-bundle with layer jobs and orchestrator.
4. Regenerate README.md, SPEC.md, and keep TODO.md aligned with prerequisites.
5. Run Python compile checks, Terraform validation, and YAML parse checks.
6. Report completion plus remaining cloud-only functional validation steps.

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
2. Generate Terraform code for secure medallion baseline:
   - Resource group, Databricks workspace, Key Vault
   - Layer-isolated storage accounts and filesystems
   - Access connectors per layer
   - Layer identity mode create|existing with least-privilege RBAC
   - Terraform outputs contract for DAB deploy bridge
3. Generate Databricks Asset Bundle:
   - databricks.yml with resources include and declared variables
   - jobs.yml with Bronze/Silver/Gold jobs plus orchestrator
   - Per-task compute declarations and path-safe spark_python_task entries
4. Regenerate README.md, SPEC.md, TODO.md aligned with Part I controls.
5. Run validation checks:
   - Python compile checks
   - Terraform init -backend=false and terraform validate
   - YAML parse for workflows and DAB files
6. Report implementation status and remaining cloud-only prerequisites.

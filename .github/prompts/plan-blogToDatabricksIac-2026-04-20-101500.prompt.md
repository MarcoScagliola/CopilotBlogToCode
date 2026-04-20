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

Implementation steps:
1. Parse Part I architecture controls:
   - Per-layer identity isolation (Bronze/Silver/Gold service principals)
   - Per-layer storage segregation (three ADLS Gen2 accounts)
   - Per-layer compute segregation (three dedicated job clusters)
   - Layer orchestration (orchestrator job)
   - Secrets in Azure Key Vault + Databricks secret scope pattern
   - Unity Catalog managed-table pattern with separate catalogs
2. Regenerate GitHub Actions workflows from scripts with current run context.
3. Generate Terraform for Azure resources and RBAC with restricted-tenant support:
   - layer_sp_mode=create|existing
   - No Graph-dependent data source in existing mode
   - Outputs required for DAB bridge
4. Generate DAB bundle:
   - databricks.yml includes resources/*.yml
   - jobs.yml contains per-layer jobs + orchestrator + compute definitions
   - Python scripts under src/bronze|silver|gold with runtime parameters
5. Regenerate README.md, TODO.md, and SPEC.md with assumptions and post-provisioning actions.
6. Run local validations:
   - Python compile checks
   - Workflow and DAB YAML parse checks
   - Terraform init -backend=false and terraform validate
7. Report final status and blockers for cloud-only validation items.

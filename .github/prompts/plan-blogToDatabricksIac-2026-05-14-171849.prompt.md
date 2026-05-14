Run start (UTC): 2026-05-14-171849

Resolved inputs:
- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID
- existing_layer_sp_client_id_secret_name: EXISTING_LAYER_SP_CLIENT_ID
- existing_layer_sp_object_id_secret_name: EXISTING_LAYER_SP_OBJECT_ID

Source blog:
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch timestamp: 2026-05-14 (current run)

Architecture summary:
- Security-first medallion pattern with one layer identity, storage boundary, and compute boundary per Bronze/Silver/Gold.
- Azure Databricks + Unity Catalog + ADLS Gen2 + Key Vault + Entra ID managed service principals.
- Managed tables preferred; orchestration via layer jobs plus orchestrator job.

Generated artifacts:
- README.md
- SPEC.md
- TODO.md
- infra/terraform/versions.tf
- infra/terraform/providers.tf
- infra/terraform/variables.tf
- infra/terraform/locals.tf
- infra/terraform/main.tf
- infra/terraform/outputs.tf
- databricks-bundle/databricks.yml
- databricks-bundle/resources/jobs.yml
- databricks-bundle/src/setup/main.py
- databricks-bundle/src/bronze/main.py
- databricks-bundle/src/silver/main.py
- databricks-bundle/src/gold/main.py
- databricks-bundle/src/smoke_test/main.py
- .github/workflows/validate-terraform.yml
- .github/workflows/deploy-infrastructure.yml
- .github/workflows/deploy-dab.yml

Validation summary (planned checks):
- Python compile checks
- Terraform init -backend=false and validate
- YAML parse for workflows and bundle YAML
- Workflow parity check
- Bundle parity check
- Recovery handler coverage check
- Placeholder and environment token checks

TODO deferred items by section:
- Pre-deployment: 3
- Deployment-time inputs: 4
- Post-infrastructure: 3
- Post-DAB: 1
- Architectural decisions deferred: 2
Run record: blog-to-databricks-iac

Resolved Inputs
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- layer_sp_mode: create
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID
- existing_layer_sp_client_id_secret_name: EXISTING_LAYER_SP_CLIENT_ID
- existing_layer_sp_object_id_secret_name: EXISTING_LAYER_SP_OBJECT_ID

Source Blog
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch timestamp (UTC): 2026-05-14

SPEC
- Path: SPEC.md
- Summary: Secure medallion architecture with per-layer storage, identity, and compute isolation across Bronze/Silver/Gold on Azure Databricks. AKV-backed secret scopes and Unity Catalog governance are central controls. CI/CD implementation specifics are deferred by the source article.

Generated Artifacts
- SPEC.md
- TODO.md
- README.md
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

Validation Results
- Python compile checks: passed
- Terraform init -backend=false: passed
- Terraform validate: passed
- Workflow YAML parse checks: passed
- Bundle YAML parse checks: passed
- Generator runtime reproducibility checks: passed
- validate_workflow_parity.sh: passed
- validate_bundle_parity.sh: passed
- validate_handler_coverage.sh: passed
- TODO placeholder and section checks: passed
- Functional test (optional): deferred (requires deployed Azure resources, Databricks workspace access, and runtime secret values)

Unresolved Items Deferred To TODO.md
- Pre-deployment: 3
- Deployment-time inputs: 3
- Post-infrastructure: 3
- Post-DAB: 1
- Architectural decisions deferred: 3

Resolved Inputs
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID
- layer_sp_mode: create

Source Blog
- url: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- fetch_timestamp_utc: 2026-05-14T17:15:11Z

SPEC
- path: SPEC.md
- summary:
  - Secure Medallion architecture with Bronze/Silver/Gold layer isolation.
  - One identity, storage account, access path, and compute boundary per layer.
  - Azure Key Vault backed secret scope and Unity Catalog governance model.
  - CI/CD details intentionally deferred from source article and handled by generated workflows.

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
- python_compile: passed
- terraform_init_backend_false: passed
- terraform_validate: passed
- yaml_parse_workflows: passed
- yaml_parse_bundle: passed
- generator_runtime_replay: passed
- workflow_parity_script: passed
- bundle_parity_script: passed
- handler_coverage_script: passed
- output_key_invariants: passed
- placeholder_and_comment_checks: passed
- optional_functional_test: skipped (environment prerequisites not provided in this run)

Deferred To TODO
- unresolved_count: 14
- section_counts:
  - Pre-deployment: 3
  - Deployment-time inputs: 4
  - Post-infrastructure: 3
  - Post-DAB: 2
  - Architectural decisions deferred: 2

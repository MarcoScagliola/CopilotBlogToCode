Use the blog-to-databricks-iac skill on this article:
https://techcommunity.microsoft.com/t5/analytics-on-azure-blog/secure-medallion-architecture-pattern-on-azure-databricks-part-i/ba-p/4459268

Inputs:
- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create

Resolved inputs:
- workload: blg
- environment: dev
- azure_region: uksouth
- azure_region_abbrev: uks
- github_environment: BLG2CODEDEV
- layer_sp_mode: create
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID

Source blog URL: https://techcommunity.microsoft.com/t5/analytics-on-azure-blog/secure-medallion-architecture-pattern-on-azure-databricks-part-i/ba-p/4459268
Fetch timestamp: 2026-05-12
SPEC.md path: SPEC.md

Generated artifacts:
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

Validation summary:
- Python compile (generators): pass
- Python compile (entrypoints): pass
- Terraform init/validate: pass
- Workflow YAML parse: pass
- Bundle YAML parse: pass
- validate_workflow_parity.sh: pass
- validate_bundle_parity.sh: pass
- TODO required sections/no html/no placeholders: pass
- outputs include workspace url/resource id: pass
- no azuread data source lookups: pass
- providers key vault recovery uses var.: pass

Deferred items are captured in TODO.md under all five required sections.

Use the blog-to-databricks-iac skill on this article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

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

Source blog URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Fetch timestamp: 2026-05-12

SPEC.md path: SPEC.md
Architecture summary: Security-first Medallion Architecture on Azure Databricks. Per-layer isolation via 3 ADLS Gen2 accounts, 3 Access Connectors (SAMI), 3 Entra ID SPs (created by Terraform in create mode), Azure Key Vault-backed secret scope, Unity Catalog (bronze/silver/gold catalogs), SCC/No-Public-IP Premium Databricks workspace, 4 Lakeflow Jobs (orchestrator + 3 layer jobs).

Generated artifacts:
- SPEC.md
- infra/terraform/versions.tf
- infra/terraform/providers.tf
- infra/terraform/variables.tf  (layer_sp_mode default = "create")
- infra/terraform/locals.tf
- infra/terraform/main.tf
- infra/terraform/outputs.tf
- .github/workflows/validate-terraform.yml  (generated)
- .github/workflows/deploy-infrastructure.yml  (generated)
- .github/workflows/deploy-dab.yml  (generated)
- databricks-bundle/databricks.yml
- databricks-bundle/resources/jobs.yml  (generated)
- databricks-bundle/src/setup/main.py
- databricks-bundle/src/bronze/main.py
- databricks-bundle/src/silver/main.py
- databricks-bundle/src/gold/main.py
- databricks-bundle/src/smoke_test/main.py
- README.md
- TODO.md

Validation results:
- Python compile generators: PASS
- Python compile entrypoints: PASS
- terraform init -backend=false: PASS
- terraform validate: PASS (after removing unsupported `prevent_deletion_if_contains_resources` arg from providers.tf key_vault block — not valid in azurerm ~>3.116)
- YAML parse workflows: PASS (3 files)
- YAML parse bundle: PASS (2 files)
- validate_workflow_parity.sh: PASS
- validate_bundle_parity.sh: PASS
- TODO.md sections present: PASS
- TODO.md no HTML comments: PASS
- TODO.md no unresolved placeholders: PASS
- outputs.tf exports databricks_workspace_url + databricks_workspace_resource_id: PASS
- No azuread data sources in Terraform: PASS
- providers.tf recover_soft_deleted references var.: PASS

Unresolved items deferred to TODO.md:
Pre-deployment (3): RBAC roles, Entra ID SP creation permission for create mode, GitHub Environment setup
Deployment-time inputs (3): key_vault_recovery_mode, state_strategy, scenario combination guide
Post-infrastructure (6): secret scope creation, Key Vault secrets, UC privilege model, Bronze/Silver/Gold entrypoint implementation
Post-DAB (1): end-to-end orchestrator run verification
Architectural decisions deferred (5): local-only state, shared_access_key, terraform fmt -check, cluster policies, job schedules + system tables

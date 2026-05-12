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
Architecture summary: Security-first Medallion architecture on Azure Databricks with per-layer isolation: 3 ADLS Gen2 accounts, 3 Access Connectors (SAMI), 3 Entra service principals (create mode), AKV-backed secret scope, Unity Catalog bronze/silver/gold layout, and SCC/No-Public-IP Databricks Premium workspace.

Generated artifacts:
- SPEC.md
- infra/terraform/versions.tf
- infra/terraform/providers.tf
- infra/terraform/variables.tf
- infra/terraform/locals.tf
- infra/terraform/main.tf
- infra/terraform/outputs.tf
- .github/workflows/validate-terraform.yml
- .github/workflows/deploy-infrastructure.yml
- .github/workflows/deploy-dab.yml
- databricks-bundle/databricks.yml
- databricks-bundle/resources/jobs.yml
- databricks-bundle/src/setup/main.py
- databricks-bundle/src/bronze/main.py
- databricks-bundle/src/silver/main.py
- databricks-bundle/src/gold/main.py
- databricks-bundle/src/smoke_test/main.py
- README.md
- TODO.md

Validation results:
- Python compile generators: PASS (using PowerShell Get-ChildItem expansion)
- Python compile entrypoints: PASS
- terraform init -backend=false: PASS on successful network runs (one transient provider download timeout observed)
- terraform validate: PASS
- YAML parse workflows: PASS
- YAML parse bundle: PASS
- validate_workflow_parity.sh: PASS
- validate_bundle_parity.sh: PASS
- TODO.md sections present: PASS
- TODO.md no HTML comments: PASS
- TODO.md no unresolved placeholders: PASS
- outputs.tf contains databricks_workspace_url + databricks_workspace_resource_id: PASS
- no azuread data-source lookups in Terraform: PASS
- providers.tf recover_soft_deleted_key_vaults references var.: PASS

Unresolved items deferred to TODO.md:
- Pre-deployment: RBAC, Entra create-mode permission, GitHub environment setup
- Deployment-time inputs: key_vault_recovery_mode, state_strategy, scenario selection
- Post-infrastructure: secret scope, runtime secrets, UC grants, layer entrypoint implementation
- Post-DAB: end-to-end orchestrator verification
- Architectural decisions deferred: local state strategy, storage shared-key hardening, fmt gate, cluster policy specifics, monitoring specifics

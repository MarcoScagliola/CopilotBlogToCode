Implement the secure medallion architecture from the source article into this repository with the following run context:
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
# Execution Plan – Secure Medallion Architecture (2026-04-17)

## Source
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Run Parameters
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET

## Architecture
Security-first Medallion Architecture: Bronze/Silver/Gold each run as independent Lakeflow jobs
under dedicated Entra ID service principals with per-layer ADLS Gen2 storage, Access Connectors,
Unity Catalog catalogs, and least-privilege RBAC grants.

## Key Decisions
- layer_service_principal_mode variable supports "create" and "existing" for tenant compatibility
- storage_shared_key_enabled defaults to true for AzureRM provider compatibility
- rbac_authorization_enabled used (not deprecated enable_rbac_authorization)
- Local ephemeral state in CI/CD; documented cleanup strategy in TODO.md
- All resource names derived in locals.tf from workload/environment/region
Execution steps:
1. Fetch and parse the source blog URL using the repo script.
2. Regenerate the three workflows: validate-terraform, deploy-infrastructure, and deploy-dab.
3. Generate or restore Terraform in infra/terraform with providers, naming locals, Azure resources, Databricks and Unity Catalog resources, and required outputs for DAB handoff.
4. Generate or restore Databricks Asset Bundle definitions and Python entrypoints for bronze, silver, and gold processing.
5. Generate or restore SPEC.md, TODO.md, and README.md with prerequisites, required secrets, one-time setup, workflow trigger instructions, and links.
6. Validate generated artifacts with Python syntax checks and Terraform validation.

Constraints:
- Keep Terraform and DAB responsibilities separate.
- Keep unresolved secure/runtime values in TODO.md.
- Ensure outputs include databricks_workspace_url and databricks_workspace_resource_id.
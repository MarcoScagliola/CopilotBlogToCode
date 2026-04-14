Implement the secure medallion architecture from the source article into this repository with the following run context:
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID

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
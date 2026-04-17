Implement secure medallion architecture from blog URL using the blog-to-databricks-iac skill.

Run context:
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV
- tenant_secret_name: AZURE_TENANT_ID
- subscription_secret_name: AZURE_SUBSCRIPTION_ID
- client_id_secret_name: AZURE_CLIENT_ID
- client_secret_secret_name: AZURE_CLIENT_SECRET
- sp_object_id_secret_name: AZURE_SP_OBJECT_ID
- existing_layer_sp_client_id_secret_name: EXISTING_LAYER_SP_CLIENT_ID
- existing_layer_sp_object_id_secret_name: EXISTING_LAYER_SP_OBJECT_ID

Execution steps:
1. Fetch blog content from provided URL.
2. Generate workflow files using generator scripts.
3. Recreate Terraform files in infra/terraform with create/existing identity mode support.
4. Recreate Databricks Asset Bundle files with Bronze/Silver/Gold jobs and orchestrator.
5. Ensure DAB bridge compatibility (workspace URL/resource ID outputs and variable mapping).
6. Generate SPEC.md, TODO.md, README.md.
7. Validate via Python compile, YAML parse, and terraform init -backend=false + validate.

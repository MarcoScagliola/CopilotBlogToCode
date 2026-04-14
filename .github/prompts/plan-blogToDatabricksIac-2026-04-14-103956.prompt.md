Implement the Azure Databricks secure medallion architecture from the source blog into this repository using workload `blg`, environment `dev`, region `uksouth`, and GitHub Environment `BLG2CODEDEV`.

Execution steps:
1. Regenerate the GitHub Actions workflows for validate, infrastructure deploy, and DAB deploy using the existing workflow generator scripts with `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID` as the environment secret names.
2. Generate repo-root deliverables: `SPEC.md`, `TODO.md`, and `README.md`.
3. Generate Terraform under `infra/terraform/` with provider/version constraints, variables, locals-based naming, Azure resources, Key Vault, Entra applications/service principals, Databricks workspace resources, Unity Catalog resources, and outputs required by the DAB deploy bridge.
4. Generate a Databricks Asset Bundle under `databricks-bundle/` with `databricks.yml`, `resources/jobs.yml`, and Python entrypoints for Bronze, Silver, and Gold processing.
5. Keep separation strict: Terraform owns Azure, identities, storage, Key Vault, access connectors, workspace, and Unity Catalog resources; the bundle owns only jobs, clusters, parameters, and runtime Python code.
6. Surface unresolved values only in `TODO.md`, especially tenant/subscription values, secret-scope creation, cluster policy hardening, notifications, and any optional networking decisions.
7. Validate generated artifacts where feasible with workflow generation, Terraform formatting/validation, and deploy-bridge compatibility.

Implementation constraints:
- Derive resource names from workload, environment, and region abbreviation.
- Do not hardcode secret values.
- Use AKV-backed Databricks secret scope conventions.
- Ensure Terraform outputs include `databricks_workspace_url` and `databricks_workspace_resource_id`.
- Ensure the DAB uses runtime secret access and per-layer job isolation.
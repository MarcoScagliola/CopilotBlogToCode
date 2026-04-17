---
name: blog-to-databricks-iac
description: Generate Terraform + Databricks DAB code from a blog URL.
---

# Blog to Terraform and Databricks DAB

## Overview
Converts a technical article into deployment-ready infrastructure code: Terraform for Azure resources and Databricks Declarative Automation Bundles for jobs/clusters. Produces SPEC.md, TODO.md, code, and README with assumptions.

## Detailed Operational Reference
For complete implementation history, validated remediations, and troubleshooting patterns, use:
- `.github/skills/blog-to-databricks-iac/references/implementation-learnings.md`

Keep this SKILL concise and procedural. Keep detailed learnings in the references folder.

## Output
1. `SPEC.md` – architecture summary
2. `TODO.md` – unresolved values
3. Terraform code (`infra/terraform/`)
4. DAB project (`databricks-bundle/`)
5. `README.md` – deployment guide
6. Execution plan prompt under `.github/prompts/` with the execution date appended to filename

## Implementation Steps

### 0. Collect run parameters

Ask the user for the following values before proceeding. If they were already provided in the request, use them directly without asking again.

| Parameter | Description | Example |
|---|---|---|
| `workload` | Short identifier for the workload, derived from the blog/project name | `blg`, `myapp`, `etl` |
| `environment` | Target deployment environment | `dev`, `prd` |
| `azure_region` | Azure region for deployment | `uksouth`, `eastus2` |
| `github_environment` | GitHub Environment name that holds `tenant`, `subscription`, `client id`, and `client secret` secrets | `MYAPP-DEV`, `BLG2CODEDEV` |
| `tenant_secret_name` | GitHub secret name that stores Azure tenant ID | `AZURE_TENANT_ID`, `MY_TENANT_ID` |
| `subscription_secret_name` | GitHub secret name that stores Azure subscription ID | `AZURE_SUBSCRIPTION_ID`, `MY_SUBSCRIPTION_ID` |
| `client_id_secret_name` | GitHub secret name that stores Azure service principal client ID | `AZURE_CLIENT_ID`, `MY_CLIENT_ID` |
| `client_secret_secret_name` | GitHub secret name that stores Azure service principal client secret | `AZURE_CLIENT_SECRET`, `MY_CLIENT_SECRET` |
| `sp_object_id_secret_name` | GitHub secret name that stores deployment principal object ID (for RBAC assignments) | `AZURE_SP_OBJECT_ID`, `MY_SP_OBJECT_ID` |
| `existing_layer_sp_client_id_secret_name` | Optional GitHub secret name for existing layer principal client ID (used when mode = `existing`) | `EXISTING_LAYER_SP_CLIENT_ID`, `LAYER_RUNNER_CLIENT_ID` |
| `existing_layer_sp_object_id_secret_name` | Optional GitHub secret name for existing layer principal object ID (used when mode = `existing`) | `EXISTING_LAYER_SP_OBJECT_ID`, `LAYER_RUNNER_OBJECT_ID` |

Store these as the active run context. Reference them as `{workload}`, `{environment}`, `{azure_region}`, `{github_environment}`, `{tenant_secret_name}`, `{subscription_secret_name}`, `{client_id_secret_name}`, `{client_secret_secret_name}`, `{sp_object_id_secret_name}`, `{existing_layer_sp_client_id_secret_name}`, `{existing_layer_sp_object_id_secret_name}` throughout all subsequent steps.

If the user does not provide:
- `github_environment`: derive a default as `{WORKLOAD_UPPER}-{ENVIRONMENT_UPPER}` (e.g. workload `blg` + environment `dev` -> `BLG-DEV`)
- `tenant_secret_name`: default to `AZURE_TENANT_ID`
- `subscription_secret_name`: default to `AZURE_SUBSCRIPTION_ID`
- `client_id_secret_name`: default to `AZURE_CLIENT_ID`
- `client_secret_secret_name`: default to `AZURE_CLIENT_SECRET`
- `sp_object_id_secret_name`: default to `AZURE_SP_OBJECT_ID`
- `existing_layer_sp_client_id_secret_name`: default to `EXISTING_LAYER_SP_CLIENT_ID`
- `existing_layer_sp_object_id_secret_name`: default to `EXISTING_LAYER_SP_OBJECT_ID`

Notes:
- Keep secret naming configurable. Do not assume organization-specific secret names.
- Existing-layer principal secrets are only required when `layer_sp_mode=existing`.
- Single-principal mapping (common in restricted tenants):
	- Use the same principal behind `{client_id_secret_name}` for both deployment and layer execution.
	- `{existing_layer_sp_client_id_secret_name}` can point to the same value as `{client_id_secret_name}`.
	- `{sp_object_id_secret_name}` and `{existing_layer_sp_object_id_secret_name}` should both use the object ID of that same principal.

### 1. Fetch article
```bash
python .github/skills/blog-to-databricks-iac/scripts/fetch_blog.py "<URL>"
```
If fetch fails, stop and return the fetch error output.

### 1.1 Save execution plan prompt
Before generating code, create and save the execution plan in `.github/prompts/` as:
`plan-blogToDatabricksIac-YYYYY-MM-DD-HHmmss.prompt.md`

Rules:
- The file must contain the current execution plan content only (no YAML frontmatter).
- Always append the execution date in `YYYY-MM-DD` format.
- Keep only 3 full execution plan files in total, delete older ones if necessary.

### 1.2 Generate validation workflow dynamically
Before generating Terraform/DAB code, create (or refresh) `.github/workflows/validate-terraform.yml` by running:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_validate_workflow.py \
	--workflow-name "Validate Terraform" \
	--github-environment "{github_environment}" \
	--tenant-secret "{tenant_secret_name}" \
	--subscription-secret "{subscription_secret_name}"
```

### 1.3 Generate infrastructure deploy workflow dynamically
Create (or refresh) `.github/workflows/deploy-infrastructure.yml` by running:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_workflow.py \
	--workflow-name "Deploy Infrastructure" \
	--github-environment "{github_environment}" \
	--tenant-secret "{tenant_secret_name}" \
	--subscription-secret "{subscription_secret_name}" \
	--client-id-secret "{client_id_secret_name}" \
	--client-secret-secret "{client_secret_secret_name}" \
	--sp-object-id-secret "{sp_object_id_secret_name}" \
	--default-workload "{workload}" \
	--default-environment "{environment}" \
	--default-region "{azure_region}"

# Optional flags (only needed when identity reuse mode is supported in workflow validation):
# 	--existing-layer-sp-client-id-secret "{existing_layer_sp_client_id_secret_name}" \
# 	--existing-layer-sp-object-id-secret "{existing_layer_sp_object_id_secret_name}"
```

Workflow credential-resolution policy (must be enforced by generated workflow):
- Resolve ARM auth values from **GitHub Secrets or GitHub Environment Variables** with secrets preferred.
	- Pattern: `secrets.<NAME> || vars.<NAME>` for tenant, subscription, client id, client secret, and object IDs.
- Validate required ARM values before Terraform runs and fail fast with a clear missing-variable list.
- Drive Terraform identity variables from resolved ARM env values (for example `TF_VAR_azure_client_id` from `ARM_CLIENT_ID`) rather than duplicating credential sources.
- When `layer_sp_mode=existing`, validate existing-layer principal identifiers; otherwise do not require them.

This workflow runs only `terraform apply` and uploads Terraform outputs as a workflow artifact named `terraform-outputs`.
It also uploads a `deploy-context` artifact that records the intended DAB target, environment, and source commit SHA for downstream deployment.

### 1.4 Generate DAB deploy workflow dynamically
Create (or refresh) `.github/workflows/deploy-dab.yml` by running:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_dab_workflow.py \
	--workflow-name "Deploy DAB" \
	--github-environment "{github_environment}" \
	--tenant-secret "{tenant_secret_name}" \
	--subscription-secret "{subscription_secret_name}" \
	--client-id-secret "{client_id_secret_name}" \
	--client-secret-secret "{client_secret_secret_name}"
```

This workflow downloads the `terraform-outputs` and `deploy-context` artifacts from the infrastructure workflow run, checks out the matching commit SHA, and then deploys the Databricks Asset Bundle. **No Databricks PAT is required.** The Databricks CLI authenticates using the same Azure Service Principal (`ARM_CLIENT_ID` / `ARM_CLIENT_SECRET` / `ARM_TENANT_ID`) already used by Terraform, combined with the workspace resource ID from the `databricks_workspace_resource_id` Terraform output.

**Required GitHub secrets/variables** (all known before deployment):
- From GitHub Environment `{github_environment}`: `{tenant_secret_name}`, `{subscription_secret_name}`, `{client_id_secret_name}`, `{client_secret_secret_name}`, `{sp_object_id_secret_name}`
- Conditional for `layer_sp_mode=existing`: `{existing_layer_sp_client_id_secret_name}`, `{existing_layer_sp_object_id_secret_name}`

**Architecture-specific runtime secrets** (vary by blog — add to TODO.md if the architecture requires them):
- Source database credentials should be populated in Azure Key Vault after infrastructure deployment, not injected into the infrastructure workflow.

**Terraform output requirement**: `outputs.tf` must export `databricks_workspace_resource_id` (the full Azure resource ID of the workspace) in addition to `databricks_workspace_url`.

### 2. Apply Terraform code generation best practices
Before generating or validating Terraform code, load and apply the principles from `.github/skills/terraform/SKILL.md`.

### 3. Validate output
- **DAB**: syntactically valid, uses placeholders for unknowns
- **TODO**: only unresolved values
- **Separation**: no Terraform resources in DAB, no jobs/notebooks in Terraform
- **Code**: production-ready, no fictional values, assumptions explicit

### 4. Generate README

Create or update `README.md` at the repository root. It must include:

1. **Architecture overview** — 2-3 sentences summarising the pattern from the blog
2. **Prerequisites** — Azure Service Principal with required permissions and GitHub Environment setup
3. **Required GitHub secrets table** — split into two groups:
	- Always required (SP credentials)
   - Architecture-specific (e.g. JDBC credentials — only list what the generated code actually uses)
4. **One-time setup steps** — register SP, assign RBAC roles, configure GitHub Environment
5. **How to trigger each workflow** — validate-terraform, deploy-infrastructure, and deploy-dab
6. **Links** to `SPEC.md` and `TODO.md`

Do NOT include credential values, connection strings, or subscription IDs in `README.md`.

### 5. Mandatory correctness validation before completion
Run all checks below before declaring generation complete:

1. Python compile checks on generator scripts, DAB deploy bridge script, and medallion Python scripts.
2. Terraform checks:
	- `terraform -chdir=infra/terraform init -backend=false`
	- `terraform -chdir=infra/terraform validate`
3. YAML parse checks for workflows and DAB YAML files.
4. Generator runtime checks by executing workflow generators and confirming file regeneration succeeds.

Mandatory guardrails:
- Generated workflows must resolve ARM credentials with `secrets.<NAME> || vars.<NAME>`.
- In `layer_sp_mode=existing`, generated workflow logic must support fallback to deployment principal values.
- Terraform outputs must include both `databricks_workspace_url` and `databricks_workspace_resource_id` for the DAB bridge.
- DAB layer scripts must not hardcode environment-specific table paths; pass catalog/schema via task parameters.
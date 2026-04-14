---
name: blog-to-databricks-iac
description: Generate Terraform + Databricks DAB code from a blog URL.
---

# Blog to Terraform and Databricks DAB

## Overview
Converts a technical article into deployment-ready infrastructure code: Terraform for Azure resources and Databricks Declarative Automation Bundles for jobs/clusters. Produces SPEC.md, TODO.md, code, and README with assumptions.

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
| `github_environment` | GitHub Environment name that holds the tenant and subscription secrets | `MYAPP-DEV`, `BLG2CODEDEV` |
| `tenant_secret_name` | GitHub secret name that stores Azure tenant ID | `AZURE_TENANT_ID`, `MY_TENANT_ID` |
| `subscription_secret_name` | GitHub secret name that stores Azure subscription ID | `AZURE_SUBSCRIPTION_ID`, `MY_SUBSCRIPTION_ID` |

Store these as the active run context. Reference them as `{workload}`, `{environment}`, `{azure_region}`, `{github_environment}`, `{tenant_secret_name}`, `{subscription_secret_name}` throughout all subsequent steps.

If the user does not provide:
- `github_environment`: derive a default as `{WORKLOAD_UPPER}-{ENVIRONMENT_UPPER}` (e.g. workload `blg` + environment `dev` -> `BLG-DEV`)
- `tenant_secret_name`: default to `AZURE_TENANT_ID`
- `subscription_secret_name`: default to `AZURE_SUBSCRIPTION_ID`

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
	--subscription-secret "{subscription_secret_name}"
```

This workflow runs only `terraform apply` and uploads Terraform outputs as a workflow artifact named `terraform-outputs`.
It also uploads a `deploy-context` artifact that records the intended DAB target, environment, and source commit SHA for downstream deployment.

### 1.4 Generate DAB deploy workflow dynamically
Create (or refresh) `.github/workflows/deploy-dab.yml` by running:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_dab_workflow.py \
	--workflow-name "Deploy DAB" \
	--github-environment "{github_environment}" \
	--tenant-secret "{tenant_secret_name}" \
	--subscription-secret "{subscription_secret_name}"
```

This workflow downloads the `terraform-outputs` and `deploy-context` artifacts from the infrastructure workflow run, checks out the matching commit SHA, and then deploys the Databricks Asset Bundle. **No Databricks PAT is required.** The Databricks CLI authenticates using the same Azure Service Principal (`ARM_CLIENT_ID` / `ARM_CLIENT_SECRET` / `ARM_TENANT_ID`) already used by Terraform, combined with the workspace resource ID from the `databricks_workspace_resource_id` Terraform output.

**Required GitHub secrets** (all known before deployment):
- From GitHub Environment `{github_environment}`: `{tenant_secret_name}`, `{subscription_secret_name}`
- Repository secrets: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `DATABRICKS_ACCOUNT_ID`, `DATABRICKS_METASTORE_ID`

**Architecture-specific secrets** (vary by blog — add to TODO.md if the architecture requires them):
- Source database credentials: `JDBC_HOST`, `JDBC_DATABASE`, `JDBC_USER`, `JDBC_PASSWORD`

**Terraform output requirement**: `outputs.tf` must export `databricks_workspace_resource_id` (the full Azure resource ID of the workspace) in addition to `databricks_workspace_url`.

### 2. Validate deployment model
Load from `./references/azure/cloud-deployment.md` and ensure conformance.

### 3. Apply core variables policy
Load from `./references/azure/core-variables.md` and enforce the mandatory baseline inputs `TODO_AZURE_TENANT_ID` and `TODO_AZURE_SUBSCRIPTION_ID` as unresolved values unless securely provided.

### 4. Apply region policy
Load from `./references/azure/region-policy.md` and apply to region inputs.

### 5. Apply naming conventions
Load from `./references/azure/naming-conventions.md`. All resource names must be derived in `locals.tf` from `workload`, `environment`, and `azure_region`. Do not accept resource names as Terraform input variables.

### 6. Validate output
Terraform: syntactically valid, internally consistent
DAB: syntactically valid, uses placeholders for unknowns
TODO: only unresolved values
Separation: no Terraform resources in DAB, no jobs/notebooks in Terraform
Code: production-ready, no fictional values, assumptions explicit

### 7. Generate README

Create or update `README.md` at the repository root. It must include:

1. **Architecture overview** — 2-3 sentences summarising the pattern from the blog
2. **Prerequisites** — Azure Service Principal with required permissions, Databricks account ID, GitHub Environment setup
3. **Required GitHub secrets table** — split into two groups:
   - Always required (SP credentials, Databricks account/metastore IDs)
   - Architecture-specific (e.g. JDBC credentials — only list what the generated code actually uses)
4. **One-time setup steps** — register SP, assign RBAC roles, configure GitHub Environment
5. **How to trigger each workflow** — validate-terraform, deploy-infrastructure, and deploy-dab
6. **Links** to `SPEC.md` and `TODO.md`

Do NOT include credential values, connection strings, or subscription IDs in `README.md`.
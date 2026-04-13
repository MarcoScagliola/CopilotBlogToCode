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

### 1. Fetch article
```bash
python .github/skills/blog-to-databricks-iac/scripts/fetch_blog.py "<URL>"
```
If fetch fails, stop and return the fetch error output.

### 1.1 Save execution plan prompt
Before generating code, create and save the execution plan in `.github/prompts/` as:
`plan-blogToDatabricksIac-YYYY-MM-DD.prompt.md`

Rules:
- The file must contain the current execution plan content only (no YAML frontmatter).
- Always append the execution date in `YYYY-MM-DD` format.
- If a file already exists for the same date, append time as `YYYY-MM-DD-HHmmss` to avoid overwrite.

### 1.2 Generate validation workflow dynamically
Before generating Terraform/DAB code, create (or refresh) `.github/workflows/validate-terraform.yml` by running:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_validate_workflow.py \
	--workflow-name "Validate Terraform" \
	--github-environment "BLG2CODEDEV" \
	--tenant-secret "AZURE_TENANT_ID" \
	--subscription-secret "AZURE_SUBSCRIPTION_ID"
```

### 1.3 Generate deploy workflow dynamically
Create (or refresh) `.github/workflows/deploy.yml` by running:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_workflow.py \
	--github-environment "BLG2CODEDEV" \
	--tenant-secret "AZURE_TENANT_ID" \
	--subscription-secret "AZURE_SUBSCRIPTION_ID"
```

This workflow runs `terraform apply` then — if no errors — reads the Terraform outputs and deploys the Databricks Asset Bundle automatically. It uses environment secrets for tenant/subscription and requires these additional GitHub secrets: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `DATABRICKS_TOKEN`, `DATABRICKS_ACCOUNT_ID`, `DATABRICKS_METASTORE_ID`, `JDBC_HOST`, `JDBC_DATABASE`, `JDBC_USER`, `JDBC_PASSWORD`.

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
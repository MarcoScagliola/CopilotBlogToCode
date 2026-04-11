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

### 2. Validate deployment model
Load from `./references/azure/cloud-deployment.md` and ensure conformance.

### 3. Apply region policy
Load from `./references/azure/region-policy.md` and apply to region inputs.

### 4. Apply naming conventions
Load from `./references/azure/naming-conventions.md`. All resource names must be derived in `locals.tf` from `workload`, `environment`, and `azure_region`. Do not accept resource names as Terraform input variables.

### 5. Validate output
Terraform: syntactically valid, internally consistent
DAB: syntactically valid, uses placeholders for unknowns
TODO: only unresolved values
Separation: no Terraform resources in DAB, no jobs/notebooks in Terraform
Code: production-ready, no fictional values, assumptions explicit
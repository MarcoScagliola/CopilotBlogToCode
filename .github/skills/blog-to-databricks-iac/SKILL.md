---
name: blog-to-databricks-iac
description: Use this skill when the user provides a technical blog URL and wants Terraform plus Declarative Automation Bundles (DAB) code generated from the article.
---

# Blog URL to Terraform + DAB

This skill converts a technical article into implementation-ready infrastructure code.

## When to use this skill

Use this skill when:
- the user gives a public blog URL
- the user wants Terraform code
- the user wants Databricks Declarative Automation Bundles (DAB) code
- the user wants infra inferred from architecture, setup, pipeline, job, storage, secrets, identities, networking, or deployment details in a blog post
- all infrastructure should be generated as Terraform, except Databricks jobs, clusters, and notebooks which should be generated as DAB
- the output must be deployment-ready (not tutorial-only)
- naming should follow Microsoft CAF style where possible

## Goal

Given a blog URL, produce:
1. a concise architecture/spec summary
2. a gap list of unknown values
3. Terraform code
4. a DAB project with `databricks.yml`
5. a README explaining assumptions and deployment steps

## Deployment Model: Clean Deployment

**This skill generates infrastructure code for a clean, greenfield deployment.** All components are created from scratch, with the following exceptions:

**Pre-existing (not created by this skill):**
- Azure tenant (Microsoft Entra ID)
- Azure subscription
- Databricks account (as the control plane for workspace provisioning)

**Created by this skill's output:**
- Azure resource group
- Azure storage accounts (bronze, silver, gold ADLS Gen2 with HNS)
- Azure managed identities (×3, one per layer)
- Key Vault and all secrets
- Databricks workspace (via Terraform)
- Databricks access connectors (×3, one per layer)
- Entra service principals and app registrations (×3)
- Unity Catalog storage credentials, external locations, catalogs, and schemas
- All RBAC and least-privilege access grants
- (Optional) Azure networking: VNet, subnets, NSGs if required
- Databricks Lakeflow jobs via DAB
- Job clusters and compute configurations

**Result: A fully isolated, production-ready medallion architecture with no external integrations or inherited resources.**

## Required behavior

### 1) Fetch and extract the article
Run:

```bash
python .github/skills/blog-to-databricks-iac/scripts/fetch_blog.py "<BLOG_URL>" > /tmp/blog_spec.json
```

If fetch fails, stop and return the structured error from `fetch_blog.py`.

### 2) Region and placeholder policy
- Preferred region policy:
	- Use region from explicit blog signal if provided.
	- Otherwise default to `uksouth`.
- If `uksouth` is used as default, do not list region as unresolved in TODO.
- Never invent concrete values for:
	- IDs (subscription, tenant, account, metastore, principal IDs)
	- secrets or secret values
	- hostnames/URLs
	- final resource names not explicitly provided by user/blog
- Use clear placeholder tokens for unknown values (example: `<TODO_DATABRICKS_WORKSPACE_URL>`).

### 3) Responsibility boundaries (strict)
Terraform owns:
- Azure resources (RG, networking if required, ADLS Gen2, Key Vault)
- managed identities, Entra apps/service principals, RBAC
- Databricks account-level identity registration
- Unity Catalog infra objects (storage credentials, external locations, catalogs/schemas/grants)

DAB owns:
- Lakeflow jobs
- job cluster definitions
- notebooks or Python entrypoints

Do not mix these concerns.

### 4) Output contract
Return outputs in this order:
1. `SPEC.md`
2. `TODO.md`
3. Terraform files under `infra/terraform/`
4. DAB files under `databricks-bundle/`
5. `README.md`

Use the template at `.github/skills/blog-to-databricks-iac/templates/output-contract.md`.

### 5) Terraform requirements
Generate exactly:
- `infra/terraform/versions.tf`
- `infra/terraform/providers.tf`
- `infra/terraform/variables.tf`
- `infra/terraform/main.tf`
- `infra/terraform/outputs.tf`

Include infra required by the blog pattern:
- 3 storage accounts (bronze/silver/gold) + containers
- 3 managed identities + 3 Databricks access connectors
- 3 Entra service principals and Databricks account registration
- Key Vault and least-privilege RBAC
- Unity Catalog storage credentials, external locations, catalogs/schemas, and grants
- optional networking resources only if explicitly required or user-requested

### 6) DAB requirements
Generate:
- `databricks-bundle/databricks.yml`
- `databricks-bundle/resources/jobs.yml`
- `databricks-bundle/resources/pipelines.yml` only if DLT is intentionally required
- `databricks-bundle/src/main.py` or equivalent notebook files

Lakeflow requirements:
- one job per medallion layer (Bronze, Silver, Gold)
- one orchestrator job chaining layer jobs
- run-as identities must remain per-layer

### 7) TODO requirements
`TODO.md` must contain unresolved values only.

Examples:
- workspace/account IDs
- catalog/schema names
- secret scope name
- schedules
- networking IDs
- storage/container names

Do not include resolved defaults (e.g., `azure_region=uksouth` if used by default).

### 8) Quality bar
- Keep code production-oriented and minimal.
- Avoid fictional values.
- Keep assumptions explicit.
- Ensure Terraform and DAB can be independently validated.

### 9) Validation checklist
Before finalizing generation:
- Terraform files are syntactically valid and internally consistent.
- DAB files are syntactically valid and reference placeholders where needed.
- TODO contains only unresolved values.
- No Terraform resources are defined in DAB and no jobs/notebooks are defined in Terraform.
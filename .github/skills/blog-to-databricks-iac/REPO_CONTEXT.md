# Repository Context

## Purpose
This document captures information specific to **this repository's** generation and deployment setup that does not generalize to other Databricks-on-cloud projects. It is a companion to the skills, not a replacement for them.

**Skills carry the rules. This file carries the parameters.**

When something is generally true (a `for_each` discipline rule, a `databricks.yml` constraint, an entrypoint singleton rule), it belongs in a skill. When something is true only because *this repo* chose it (a default region, a validation command, a specific bridge variable), it belongs here.

## When to load this file
Load `repo-context.md` when:
- Generating CI/CD workflows that need this repo's specific environment names, tenant defaults, or naming components.
- Running post-generation validation and you need the exact commands this repo uses.
- Resolving ambiguity about which variables this repo's deploy bridge expects.
- Filling in default values for an interactive run (workload code, region abbreviation, environment name) where the user has not specified them.

Do not load this file for routine code generation. The leaf skills (`terraform`, `databricks-asset-bundle`, `databricks-yml-authoring`, `python-entrypoints`) carry the rules that govern *how* code is written. This file only carries *what specific values* to plug in.

## Run Context Defaults
When the user does not specify these values, use the defaults below.

| Parameter | Default | Notes |
|---|---|---|
| `workload` | `blg` | Three-letter workload identifier used in resource naming. |
| `environment` | `dev` | Lowest-risk environment; the default target for unattended runs. |
| `azure_region` | `uksouth` | Region for all Azure resources in this repo. |
| `azure_region_abbrev` | `uks` | Used inside resource names where length matters. |
| `github_environment` | `BLG2CODEDEV` | GitHub Actions environment that holds secrets and variables. |

## GitHub Actions Credential Resolution
This repo uses **both** GitHub Secrets and GitHub Environment Variables for ARM credentials, depending on which environment is being targeted. Generated workflows must resolve credentials with a fallback:

```yaml
${{ secrets.AZURE_CLIENT_ID || vars.AZURE_CLIENT_ID }}
${{ secrets.AZURE_TENANT_ID || vars.AZURE_TENANT_ID }}
${{ secrets.AZURE_SUBSCRIPTION_ID || vars.AZURE_SUBSCRIPTION_ID }}
${{ secrets.AZURE_CLIENT_SECRET || vars.AZURE_CLIENT_SECRET }}
${{ secrets.AZURE_SP_OBJECT_ID || vars.AZURE_SP_OBJECT_ID }}
```

Applies to: `deploy-infrastructure.yml`, `deploy-dab.yml`, and any workflow generator that produces them.

## Existing-Identity Mode Fallbacks
When `layer_sp_mode = "existing"` is selected, `EXISTING_*` inputs are not always set explicitly. The deployment principal is reusable, so generated code falls back to it:

| Missing input | Falls back to |
|---|---|
| `existing_client_id` | `AZURE_CLIENT_ID` |
| `existing_object_id` | `AZURE_SP_OBJECT_ID` |

The fallback logic lives in the workflow generators and the Terraform `locals.tf`. The general rule for handling restricted-tenant identity reuse lives in the `terraform` skill (Principle 3); this section only documents *which specific environment variables* this repo falls back to.

## Deploy Bridge Variable Contract
The deploy bridge (`scripts/azure/deploy_dab.py`) maps Terraform outputs to `databricks bundle deploy --var` flags. The variables exchanged across that boundary in this repo:

| Terraform output | Bundle variable | Purpose |
|---|---|---|
| `databricks_workspace_resource_id` | `workspace_resource_id` | Required for Azure auth context in DAB. |
| `bronze_catalog`, `silver_catalog`, `gold_catalog` | same names | Per-layer catalog identifiers. |
| `bronze_schema`, `silver_schema`, `gold_schema` | same names | Per-layer schema identifiers. |
| `secret_scope` | same name | Key-Vault-backed secret scope. |
| `bronze_principal_client_id`, `silver_principal_client_id`, `gold_principal_client_id` | same names | Per-layer service principal client IDs. |
| `bronze_storage_account`, `silver_storage_account`, `gold_storage_account` | same names | Per-layer storage account names. |
| `bronze_access_connector_id`, `silver_access_connector_id`, `gold_access_connector_id` | same names | Per-layer Databricks access connector resource IDs. |

`workspace_host` is **not** part of this contract. The bundle's auth host is supplied via the `DATABRICKS_HOST` environment variable, set in the workflow before invoking `databricks bundle deploy`. See the `databricks-yml-authoring` skill for the rule (auth fields cannot interpolate variables).

The general rule for keeping bridge and bundle variable sets in one-to-one correspondence lives in the `databricks-asset-bundle` skill. This section only documents the specific variables this repo's bridge passes.

## Validation Commands
Run these after any generation pass, before declaring success.

### Python
Compile generator scripts, the deploy bridge, and all entrypoints. The `find`-based form is portable across shells and doesn't depend on `globstar` being enabled.

```bash
python -m py_compile .github/skills/blog-to-databricks-iac/scripts/azure/*.py
find databricks-bundle/src -name 'main.py' -exec python -m py_compile {} +
```

### Terraform
Validate without contacting a backend.

```bash
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
```

### YAML
Parse all generated workflows and bundle files.

```bash
python -c "import yaml, glob; [yaml.safe_load(open(f)) for f in glob.glob('.github/workflows/*.yml')]"
python -c "import yaml, glob; [yaml.safe_load(open(f)) for f in glob.glob('databricks-bundle/**/*.yml', recursive=True)]"
```

### Generators
Re-run each and confirm output is reproducible.

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_jobs_bundle.py
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_workflow.py
```

A clean run produces no errors and no diff against the prior generation when inputs are unchanged.

## Idempotent Generation Policy
This repo's outputs are regenerated frequently. Manual edits to generated files are lost on the next regeneration.

**Rules:**
1. Behavior changes go in generators or skills, not in their outputs.
2. If a one-off manual edit is required (e.g. emergency unblock), mirror the change back to the generator before the next regeneration.
3. Workspace resets and CI environment rebuilds happen often enough that any state not encoded in the repo is assumed lost.

The general principle of idempotent generation is in the `blog-to-databricks-iac` orchestrator skill. The list below names the *specific files* in this repo that are produced by generators (or, in the case of `databricks.yml`, re-authored by a skill) and must not be hand-edited:

- `.github/workflows/validate-terraform.yml`
- `.github/workflows/deploy-infrastructure.yml`
- `.github/workflows/deploy-dab.yml`
- `databricks-bundle/resources/jobs.yml`
- `databricks-bundle/databricks.yml` *(re-authored by the `databricks-yml-authoring` skill; the singleton-replacement rule applies — never patch in place, always replace wholesale)*

## Policy: Learnings Become Rules
When a deploy fails or a generation pass produces broken output, the resolution process is:

1. Diagnose the failure mode.
2. Identify the rule that, if followed, would have prevented it.
3. Add the rule to the skill that owns the relevant artifact:
   - Terraform code → `terraform` skill
   - `databricks.yml` → `databricks-yml-authoring` skill
   - `resources/*.yml` and bundle structure → `databricks-asset-bundle` skill
   - Python entrypoints → `python-entrypoints` skill
   - Cross-skill orchestration → `blog-to-databricks-iac` skill
   - Repo-specific values (variable names, defaults, commands) → this file
4. Verify the fix by regenerating from scratch and confirming the failure does not recur.

There is no "implementation-learnings" or "troubleshooting log" file in this repo by policy. Each learning becomes a rule in a skill or a parameter in this file. Bug histories live in `git log` and PR descriptions.

If you find yourself wanting to append a learning to a growing list, that is the signal to ask: **what rule does this learning encode, and which skill should carry that rule?**
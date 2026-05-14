# Welcome: How To Use This Repo

This repository is designed to turn a Databricks architecture blog or technical specification into ready-to-run delivery assets using the blog-to-databricks-iac skill.

**This reposiroty produces infra code for only clean deployments and is NOT production ready**

You can use it as a repeatable generator workflow:
- reset
- fetch/analyze
- generate
- validate
- deploy

The result is a clean and professional baseline for Azure Databricks projects.

## What This Skill Produces

When you run the skill correctly, this repo will produce:

1. Terraform infrastructure code for Azure in [infra/terraform](infra/terraform)
2. Databricks Asset Bundle structure in [databricks-bundle](databricks-bundle)
3. Databricks jobs definition file in [databricks-bundle/resources/jobs.yml](databricks-bundle/resources/jobs.yml)
4. Python entrypoints for setup/bronze/silver/gold/smoke tests in [databricks-bundle/src](databricks-bundle/src)
5. GitHub Actions workflows in [.github/workflows](.github/workflows)
6. Architecture summary in [SPEC.md](SPEC.md)
7. Operator checklist in [TODO.md](TODO.md)
8. Repository usage guide in [README.md](README.md)
9. Source article extraction artifacts in [blog_fetch_output.json](blog_fetch_output.json) and [blog_fetch_output.extracted.md](blog_fetch_output.extracted.md)

## Quick Start

1. Open terminal at repository root.
2. Reset generated assets.
3. Fetch the article.
4. Run workflow generators.
5. Generate jobs bundle.
6. Validate Terraform, YAML, and parity checks.

## Reset: Start Clean Every Time

Use this before a new generation pass:

```powershell
python .github/skills/blog-to-databricks-iac/scripts/reset_generated.py --force
```

What reset does:
- removes generated infrastructure and bundle output
- keeps the skill scripts/templates intact
- gives you deterministic regeneration

## Required Inputs (Main Parameters)

These are the core inputs you normally provide to the skill:

1. workload
    - short code for resource naming
    - example: blg

2. environment
    - target environment label
    - example: dev

3. azure_region
    - Azure deployment region
    - example: uksouth

4. layer_sp_mode
    - identity source model for layer service principals
    - allowed: create or existing

5. github_environment
    - GitHub Actions Environment name used for secrets/variables
    - example: BLG2CODEDEV

## Optional Secret Name Parameters

You can keep defaults or override if your organization uses custom names:

1. tenant_secret_name (default AZURE_TENANT_ID)
2. subscription_secret_name (default AZURE_SUBSCRIPTION_ID)
3. client_id_secret_name (default AZURE_CLIENT_ID)
4. client_secret_secret_name (default AZURE_CLIENT_SECRET)
5. sp_object_id_secret_name (default AZURE_SP_OBJECT_ID)

Only when layer_sp_mode = existing:

1. existing_layer_sp_client_id_secret_name (default EXISTING_LAYER_SP_CLIENT_ID)
2. existing_layer_sp_object_id_secret_name (default EXISTING_LAYER_SP_OBJECT_ID)

## Parameter Behavior You Should Know

1. layer_sp_mode=create
    - the generated path expects per-layer identities to be created
    - useful in flexible/dev tenants

2. layer_sp_mode=existing
    - reuses pre-created identities
    - preferred in restricted tenants

3. github_environment
    - must exist in GitHub repository settings
    - workflows resolve credentials from secrets and variables in this environment

4. object IDs
    - use Enterprise Application (service principal) object IDs for RBAC
    - do not confuse with App Registration object IDs

## Example: Your Current Scenario

The following inputs are required:

1. `workload` — the name of the workload
2. `environment` — the environment label, such as `dev`, `tst`, or `test`
3. `azure_region` — the Azure region the components are being deployed to (for example, `uksouth`)
4. `layer_sp_mode` — `create` or `existing`
5. `github_environment` — the GitHub environment where the secrets and parameter values are stored


## Validation Checklist

After generation, run:

1. Python compile checks
2. Terraform init/validate
3. YAML parsing for workflows and bundle
4. workflow parity check
5. bundle parity check
6. handler coverage check
7. environment token and placeholder scan

This repository already includes these validation scripts and patterns under [.github/skills/blog-to-databricks-iac/scripts](.github/skills/blog-to-databricks-iac/scripts).

## How To Think About This Repo

This is a generation-first repo, not a manual-edit-first repo.

Best practice:
1. change behavior in skill scripts/templates
2. regenerate outputs
3. validate
4. commit

That approach keeps everything consistent and makes future reruns reliable.

## Positive Operating Guidance

You are in a strong position with this setup:
- generation is scriptable
- validation is repeatable
- workflow inputs are explicit
- outputs are structured for team handoff

Keep following the reset -> generate -> validate rhythm, and this repository will stay stable, and predictable.

# Blog to Databricks IaC - Reference and Learnings

## Purpose
This document captures implementation decisions, recurring failures, and validated fixes observed while generating this repository from the Secure Medallion Architecture blog pattern.

Use this file as the detailed operational reference.
Use `SKILL.md` as the concise execution contract.

## Recommended Documentation Pattern
- Keep `SKILL.md` short and prescriptive (what to do every run).
- Keep this `REFERENCE.md` detailed and historical (why, edge cases, known pitfalls, and validated remediations).

## Run Context Defaults
- workload: `blg`
- environment: `dev`
- azure_region: `uksouth`
- github_environment: `BLG2CODEDEV`
- tenant/subscription/client/secret/object-id names default to `AZURE_*` variants.

## Actions Implemented in This Repo
1. Added dynamic workflow generators and regenerated:
   - `.github/workflows/validate-terraform.yml`
   - `.github/workflows/deploy-infrastructure.yml`
   - `.github/workflows/deploy-dab.yml`
2. Implemented Terraform baseline in `infra/terraform` with:
   - identity mode switch (`create` vs `existing`)
   - per-layer storage + RBAC assignments
   - Key Vault and required bridge outputs
3. Implemented DAB baseline in `databricks-bundle` with:
   - medallion layer jobs + orchestrator
   - deploy bridge variable compatibility
4. Added bridge compatibility between Terraform outputs and DAB deploy variables in:
   - `.github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py`
5. Added local validation loops:
   - Python compile checks
   - YAML parse checks
   - `terraform init -backend=false` and `terraform validate`

## Critical Learnings and Guardrails

### 1. Credential Resolution Must Support Both Secrets and Vars
Issue:
- CI failures occurred when values were configured as GitHub Environment Variables instead of Secrets.

Fix:
- Generated workflows must resolve with `secrets.NAME || vars.NAME` for ARM credentials.

Applies to:
- deploy-infrastructure workflow (required)
- deploy-dab workflow (required)

### 2. Existing Identity Mode Needs Fallbacks
Issue:
- `layer_sp_mode=existing` failed when `EXISTING_*` values were not explicitly set even though deployment principal should be reusable.

Fix:
- Fallback to deployment principal values:
  - existing client id -> `AZURE_CLIENT_ID`
  - existing object id -> `AZURE_SP_OBJECT_ID`

### 3. Bridge Contract Must Include Workspace Resource ID
Issue:
- DAB deployment path requires workspace resource ID for Azure auth context.

Fix:
- `outputs.tf` must export `databricks_workspace_resource_id`.
- `deploy_dab.py` must map `workspace_resource_id` from Terraform outputs.
- `databricks.yml` must declare `workspace_resource_id` as a variable for the deploy bridge contract.
- Keep bundle workspace blocks limited to supported schema fields; use deploy-time environment variables for Azure auth context when required.
- Keep deploy bridge variable injection minimal: pass only variables that are part of the Terraform-to-bundle contract, and avoid forcing optional variables unless the bundle explicitly needs them.

### 4. Medallion Scripts Must Not Hardcode Environment Tables
Issue:
- Hardcoded `dev_*` table paths break non-dev promotions.

Fix:
- Bronze/Silver/Gold scripts consume catalog/schema via argparse.
- `resources/jobs.yml` passes required parameters to each task.

### 5. Key Vault Soft-Delete Recovery Must Be Dynamic Per Run
Issue:
- A fixed provider setting is brittle across ephemeral reruns:
   - If recovery is disabled and a soft-deleted vault exists, apply fails with recovery-disabled errors.
   - If recovery is enabled and no soft-deleted vault exists, apply can fail with `SoftDeletedVaultDoesNotExist`.

Fix:
- In `providers.tf`, make recovery configurable:
  ```hcl
  key_vault {
      recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted
  }
  ```
- In the deploy workflow, compute the expected Key Vault name and query Azure deleted vaults (`az keyvault list-deleted`).
- Set `TF_VAR_key_vault_recover_soft_deleted=true` only when a matching soft-deleted vault exists; otherwise set it to `false`.
- Expose workflow input `key_vault_recovery_mode` (`auto`, `recover`, `fresh`) so reruns can be deterministic when deleted-vault discovery is blocked or ambiguous.

Applies to:
- `infra/terraform/providers.tf`
- `infra/terraform/variables.tf`
- `.github/workflows/deploy-infrastructure.yml`
- `.github/skills/blog-to-databricks-iac/scripts/azure/generate_deploy_workflow.py`

### 6. Keep Generation Idempotent
Issue:
- Workspace resets are frequent; one-off manual edits are lost.

Fix:
- Encode behavior in generators and skills, then regenerate outputs.
- Avoid direct manual workflow edits unless mirrored back to generator scripts.

## Validation Checklist (Required Before Declaring Success)
1. Python syntax
   - `python -m py_compile` on generator scripts, deploy bridge, and medallion scripts
2. Terraform validation
   - `terraform -chdir=infra/terraform init -backend=false`
   - `terraform -chdir=infra/terraform validate`
3. YAML structure
   - Parse workflows and DAB YAML with `yaml.safe_load`
4. Generator runtime validation
   - Execute all workflow generators and confirm outputs are regenerated without errors

## Known Constraints in Current Baseline
- Databricks workspace URL/resource ID are currently emitted as placeholders/derived patterns unless full workspace provisioning is added.
- Unity Catalog objects are not fully provisioned in this simplified baseline.
- This baseline prioritizes repeatability and CI contract correctness over full production hardening.

## Suggested Next Hardening Steps
1. Provision or data-source resolve actual Databricks workspace.
2. Add Databricks provider resources for UC catalogs/schemas/grants.
3. Add remote Terraform backend strategy and import guidance.
4. Add CI plan stage and policy/security checks.

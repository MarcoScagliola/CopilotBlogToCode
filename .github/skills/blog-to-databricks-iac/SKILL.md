---
name: blog-to-databricks-iac
description: Use this skill when the user provides a blog/article URL describing an Azure data architecture based on Databricks and wants deployment-ready infrastructure generated from it. Produces Terraform (Azure), Declarative Automation Bundles (DAB), GitHub Actions workflows, and deployment docs. Triggers include "turn this blog into Terraform", "generate IaC from this article", "bootstrap a Databricks project from …". This orchestrator is optimized for end-to-end generation from a blog article. For surgical changes to existing IaC, prefer loading the relevant leaf skill (terraform, databricks-asset-bundle, etc.) directly. Use the orchestrator when the task spans multiple artifacts or starts from a fresh article.
---

# Blog to Terraform and Databricks DAB

## Overview
Converts a technical article into deployment-ready infrastructure code: Terraform for Azure resources and Databricks Declarative Automation Bundles (DAB) for jobs/clusters. Produces SPEC.md, TODO.md, code, and README with assumptions.
Deploy only the minimal required resources in Terraform for the use case described in the article.

## Repository Context and Skill Graph

This skill is the orchestrator. It routes generation work to leaf skills and consults a repository context file for repo-specific values.

### Leaf skills
Each artifact class has a dedicated skill. Load the relevant skill when authoring or modifying that artifact:

- `terraform` — for everything in `infra/terraform/`
- `databricks-asset-bundle` — for bundle structure, resource files, and parameter flow
- `databricks-yml-authoring` — for `databricks-bundle/databricks.yml` specifically
- `python-entrypoints` — for entrypoint files under `databricks-bundle/src/<job>/main.py`

The leaf skills carry the rules. This orchestrator skill does not duplicate them.

### Repository context
For repo-specific values that do not generalize (default workload code, region defaults, this repo's specific deploy bridge contract, validation commands), load `repo-context.md` from this skill's directory.

Load `repo-context.md` when:
- Generating CI/CD workflows that need this repo's specific environment names, tenant defaults, or naming components.
- Running post-generation validation and you need the exact commands this repo uses.
- Resolving ambiguity about which variables this repo's deploy bridge expects.
- Filling in default values for an interactive run where the user has not specified them.

Do not load `repo-context.md` for routine code generation — the leaf skills carry the authoring rules; this file only carries repo-specific parameters.

### Learnings policy
There is no implementation-learnings or troubleshooting log file in this repo by policy. When a generation pass produces broken output, the resolution is to identify the rule that would have prevented it and add that rule to the skill that owns the relevant artifact. Repo-specific values go to `repo-context.md`. Bug histories live in `git log` and PR descriptions.

## Output
1. `SPEC.md` – architecture summary
2. `TODO.md` – unresolved values
3. Terraform code (`infra/terraform/`)
4. DAB project (`databricks-bundle/`)
5. `README.md` – deployment guide
6. Execution plan prompt under `.github/prompts/` with the execution date appended to filename

## Inputs
Collect the following values before proceeding. If the request already contains them, use them directly. If any required value is missing from the request, ask the user for it before continuing to Implementation Steps.

### Required from user
| Parameter | Description | Example |
|---|---|---|
| `workload` | Short identifier for the workload, derived from the blog/project name | `blg`, `myapp`, `etl` |
| `environment` | Target deployment environment | `dev`, `prd` |
| `azure_region` | Azure region for deployment | `uksouth`, `eastus2` |
| `layer_sp_mode` | How per-layer service principals are sourced | `create` (default — new SPs per layer) or `existing` (reuse principal from existing-* secrets) |

### GitHub secret/variable names (defaults usually suffice)
The orchestrator generates workflows that read Azure credentials from named GitHub secrets. The defaults below match standard Azure naming conventions; override only if your organization uses different names.

| Parameter | Default | Purpose |
|---|---|---|
| `github_environment` | `{WORKLOAD_UPPER}-{ENVIRONMENT_UPPER}` | GitHub Environment containing the secrets |
| `tenant_secret_name` | `AZURE_TENANT_ID` | Azure tenant ID |
| `subscription_secret_name` | `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `client_id_secret_name` | `AZURE_CLIENT_ID` | Service principal client ID |
| `client_secret_secret_name` | `AZURE_CLIENT_SECRET` | Service principal client secret |
| `sp_object_id_secret_name` | `AZURE_SP_OBJECT_ID` | Deployment principal object ID (for RBAC) |

### Optional (only when `layer_sp_mode = existing`)
| Parameter | Default | Purpose |
|---|---|---|
| `existing_layer_sp_client_id_secret_name` | `EXISTING_LAYER_SP_CLIENT_ID` | Client ID of the existing layer principal |
| `existing_layer_sp_object_id_secret_name` | `EXISTING_LAYER_SP_OBJECT_ID` | Object ID of the existing layer principal (for RBAC) |

Reference each parameter as `{<parameter_name>}` (e.g. `{workload}`, `{tenant_secret_name}`) in subsequent steps.

### Input constraints
- Keep secret naming configurable. Do not assume organization-specific secret names.
- Existing-layer principal secrets are only required when `layer_sp_mode=existing`.
- Object ID secrets must be **Service Principal (Enterprise Application) object IDs**. Do not use App Registration object IDs.
- `*_CLIENT_SECRET` stores the credential secret value; `*_SP_OBJECT_ID` stores the principal object ID used for RBAC.
- Single-principal mapping (common in restricted tenants):
	- Use the same principal behind `{client_id_secret_name}` for both deployment and layer execution.
	- `{existing_layer_sp_client_id_secret_name}` can point to the same value as `{client_id_secret_name}`.
	- `{sp_object_id_secret_name}` and `{existing_layer_sp_object_id_secret_name}` should both use the object ID of that same principal.

## Implementation Steps

### 1. Fetch article
```bash
python .github/skills/blog-to-databricks-iac/scripts/fetch_blog.py "<URL>"
```
If fetch fails, stop and return the fetch error output. Do not retry; surface the error to the user and wait for guidance.

### 2. Analyse article
Analyse the fetched article against the structured checklist in `.github/skills/blog-to-databricks-iac/references/blog-analysis-checklist.md`. The analysis covers the article text, diagrams, screenshots, and code snippets.

Write the analysis to `SPEC.md` at the repository root. `SPEC.md` is the authoritative architecture summary for this run and is consumed by every subsequent generation step.

Rules:
- For every checklist item, record either a stated value from the article or the literal string `not stated in article`. Do not invent defaults, and do not omit items.
- Mark values inferred from diagrams or code snippets (rather than stated in prose) as `inferred from <source>`, e.g. `inferred from code snippet`, `inferred from architecture diagram`.
- Preserve names used in the article (resource names, table names, job names) where compatible with the naming conventions defined in the `terraform` skill loaded in step 3. Where a name must be transformed to be compatible, record the original and the transformed name side by side.
- Aim for one to three bullets per checklist item. Prefer precise short entries over prose.
- Do not include content outside the checklist structure. If the article mentions something interesting but not covered by the checklist, add it to a final "Other observations" section rather than scattering it through the main sections.

Every `not stated in article` entry in `SPEC.md` must appear as a TODO.md item when step 8 generates TODO.md. Step 8 depends on this mapping; do not resolve `not stated` values here by guessing.

### 3. Apply Terraform code generation best practices
Before generating or validating Terraform code, load and apply the `terraform` skill.

### 4. Generate validation workflow dynamically
Before generating Terraform/DAB code, create (or refresh) `.github/workflows/validate-terraform.yml` by running:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_validate_workflow.py \
    --workflow-name "Validate Terraform" \
    --github-environment "{github_environment}" \
    --tenant-secret "{tenant_secret_name}" \
    --subscription-secret "{subscription_secret_name}"
```

### 5. Generate infrastructure deploy workflow dynamically
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
```

Workflow credential-resolution policy (must be enforced by generated workflow):
- Resolve ARM auth values from **GitHub Secrets or GitHub Environment Variables** with secrets preferred.
- Pattern: `secrets.<NAME> || vars.<NAME>` for tenant, subscription, client id, client secret, and object IDs.
- Validate required ARM values before Terraform runs and fail fast with a clear missing-variable list.
- Drive Terraform identity variables from resolved ARM env values (for example `TF_VAR_azure_client_id` from `ARM_CLIENT_ID`) rather than duplicating credential sources.
- When `layer_sp_mode=existing`, validate existing-layer principal identifiers; otherwise do not require them.
- Include a workflow input `state_strategy` with options `fail` and `recreate_rg` to handle ephemeral-state reruns predictably.
- When `state_strategy=recreate_rg`, delete the resource group named per the canonical pattern (see "Resource name computation in the generated workflow" below — the workflow's `$rg_name` shell variable). Do not hardcode a `-platform` suffix; the suffix is the region abbreviation as defined by the `terraform` skill's Section 5 (Resource Naming).

- When `state_strategy=fail`, stop with a clear message that remote backend + import is required for non-destructive adoption.

Resource name computation in the generated workflow (must be enforced by `generate_deploy_workflow.py`):

- The canonical naming patterns are defined in the `terraform` skill's Section 5 (Resource Naming). The workflow generator must produce shell logic that computes names matching those patterns exactly. The workflow follows Terraform's naming, not the other way around.

- Compute the region abbreviation once, in an early job step, and write the result to `$GITHUB_ENV` so all later steps reference the same value. The mapping table (from `azure_region` input to abbreviation, e.g. `uksouth` → `uks`) lives in this single early step, not duplicated across multiple steps. Subsequent steps that need the abbreviation read it from the env, not from local recomputation. This eliminates the class of bug where two steps independently compute names and silently produce different values.

- The deployment workflow uses `$rg_name`, `$kv_name`, `$workspace_name`, and `$storage_name_<layer>` shell variables to refer to canonical resources. These variables must be assigned in an early step (after the region-abbreviation computation, before any step that operates on Azure resources) and reused across all later steps — state preflight, soft-delete recovery, `terraform import`, output extraction. No step may compute or hardcode a resource name; every reference goes through the variable.

- Workflow-invented suffixes such as `-platform` are not permitted. The `terraform` skill's Section 5 explicitly forbids them. If a generator currently emits `-platform`, that is a regression caught by validation invariants in 9.3.

Soft-delete recovery state machine (must be enforced by generated workflow):

- The auto mode for `key_vault_recovery_mode` follows a recovery-first strategy: the initial apply attempts with `key_vault_recover_soft_deleted=true`. The retry logic handles two failure cases:
  - If the initial apply fails with `SoftDeletedVaultDoesNotExist` (no recoverable vault exists), retry with `key_vault_recover_soft_deleted=false`.
  - If the initial apply fails with "recovering this KeyVault has been disabled" or "existing soft-deleted Key Vault exists" (which only happens when the flag was `false` going in — e.g. via `mode=fresh`, or via stale state inherited from `$GITHUB_ENV`), perform recovery and import via the recovery handler, then retry with `key_vault_recover_soft_deleted=true`.

- In auto mode, the `az keyvault list-deleted` query inside the detection step is informational — its result is logged but does not affect the recovery flag. The recovery flag is set to `true` unconditionally in auto mode (recovery-first), because detection-driven branching is unreliable when the deployment principal lacks permission to query soft-deleted vault state. The detection step still writes `TF_VAR_key_vault_recover_soft_deleted=true` to `$GITHUB_ENV` so the apply step has a defined starting value.

- The detection step must write `TF_VAR_key_vault_recover_soft_deleted` to `$GITHUB_ENV` in all three modes (`auto`, `recover`, `fresh`). It must not skip the write in any mode. This prevents stale values from a previous workflow run's mid-fallback failure from leaking into the next run's apply step.

- The apply step must echo the resolved value of `TF_VAR_key_vault_recover_soft_deleted` immediately before running `terraform apply`. This makes the state machine visible in the workflow log and helps diagnose any drift between the detection step and the apply step.

- The auto-mode fallback retries only on the specific Key Vault state errors below. All other failure classes — including configuration errors (`No value for required variable`, `Invalid value for variable`), authentication errors, and unrelated provider errors — exit immediately with the original return code. The `Configuration error detected — refusing to retry` guard is required as the first check in the failure-handling block.
  - `SoftDeletedVaultDoesNotExist` → flip recover flag from `true` to `false` and retry.
  - `recovering this KeyVault has been disabled` / `existing soft-deleted Key Vault exists` → run the recovery handler (recover the vault, import into Terraform state), then retry with `key_vault_recover_soft_deleted=true`.
  - `to be managed via Terraform this resource needs to be imported` / `already exists - to be managed via Terraform` → import the existing vault, then retry.
  
  Adding a new fallback case requires explicitly extending this list and the corresponding case in `generate_deploy_workflow.py`. Generic catch-all retries are not permitted.

- The soft-delete recovery handler's resource group and key vault names must be computed from the same conventions as `infra/terraform/locals.tf` (see the `terraform` skill's Resource naming contract). When the recovery handler runs `az group create`, `az keyvault recover`, or `terraform import`, it must reference the *Terraform-canonical* names, not workflow-invented names. Any divergence breaks the recovery path silently — the handler appears to run successfully but the subsequent retry apply fails because Terraform looks for a differently-named resource.

- The recovery handler must address two preconditions around `az keyvault recover`. Both stem from a property of Azure: soft-deleted vaults remember their original resource group, and `az keyvault recover` puts them back there — not into whatever RG the workflow happens to have computed.

  **Precondition 1: ensure the original RG exists before recovery.** If the soft-deleted vault's original resource group has been deleted (e.g. by a previous `state_strategy=recreate_rg` run), `az keyvault recover` fails with `ResourceGroupNotFound` before doing any work. The handler must run `az group create --name "$rg_name" --location "$region"` immediately before `az keyvault recover`. The command is idempotent — if the RG already exists, it succeeds without changes; if it does not, it creates it. This succeeds in the normal case (vault's original RG matches `$rg_name`, which it does for any vault created under the current naming scheme).

  **Precondition 2: verify the recovered vault landed in the canonical RG.** After `az keyvault recover` succeeds and the vault is reachable via `az keyvault show`, query its actual resource group: `actual_rg=$(az keyvault show --name "$kv_name" --query resourceGroup -o tsv)`. Compare against `$rg_name`. They should match — the vault was originally in `$rg_name` (canonical naming) and Azure recovered it back there. If they differ, the vault is from a legacy deploy that used a non-canonical naming convention. The recovery handler cannot import this cleanly into the current Terraform state without producing persistent diffs (the resource definition's RG attribute would forever disagree with the actual resource's RG). The handler must exit with status 1 and a clear operator message:

  > Recovered vault `<name>` is in resource group `<actual_rg>`, but the current Terraform configuration expects it in `<rg_name>`. This means the vault was created by a legacy deploy under a different naming convention. The recovery handler cannot import it cleanly. Resolution: purge the soft-deleted vault permanently and re-dispatch with `mode=fresh`. (Note: purging is irreversible. Back up any secrets you need before purging.)

  Together, the two preconditions handle three distinct cases:
  - Vault's original RG matches `$rg_name` and currently exists → recovery proceeds, post-recovery check passes, import succeeds.
  - Vault's original RG matches `$rg_name` but was deleted → `az group create` recreates it, recovery proceeds into the recreated RG, post-recovery check passes, import succeeds.
  - Vault's original RG differs from `$rg_name` (legacy deploy) → recovery may or may not succeed depending on whether the legacy RG still exists; either way, the post-recovery check fails and the handler exits with the operator message above.

  Cases 1 and 2 are handled silently and automatically. Case 3 fails loudly with operator instructions, because no automated handling preserves Terraform-state correctness.

Repeatability and restricted-tenant guardrails (mandatory):
- In `layer_sp_mode=existing`, treat `existing_layer_sp_object_id` as a trusted input and pass it directly to RBAC resources.
- Do **not** add Terraform data-source validation that reads Microsoft Graph for existing principals (for example `data "azuread_service_principal" "existing_layer"`).
- Keep generated infrastructure compatible with tenants where deployment identities do not have Graph directory read permissions.
- If principal validation is desired, perform it as an optional preflight step outside Terraform apply, not as a required dependency for provisioning.

This workflow runs only `terraform apply` and uploads Terraform outputs as a workflow artifact named `terraform-outputs`. It also uploads a `deploy-context` artifact that records the intended DAB target, environment, and source commit SHA for downstream deployment.

### 6. Generate DAB deploy workflow dynamically
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
- For both object ID secrets, use the object ID from **Microsoft Entra ID -> Enterprise applications** for the target principal.

**Architecture-specific runtime secrets** (vary by blog — add to TODO.md if the architecture requires them):
- Source database credentials should be populated in Azure Key Vault after infrastructure deployment, not injected into the infrastructure workflow.
- If additional service principals are required by the architecture and are not covered by the base configuration/secrets, you must explicitly document them in `TODO.md` with step-by-step implementation instructions (how to create, which permissions/roles to assign, and how to retrieve/store client ID and object ID).
- Do not require these additional service principal values as workflow dispatch inputs; document them as setup tasks in `TODO.md`.

**Terraform output requirement**: `outputs.tf` must export `databricks_workspace_resource_id` (the full Azure resource ID of the workspace) in addition to `databricks_workspace_url`.

### 7. Generate DAB jobs bundle dynamically
Create (or refresh) `databricks-bundle/resources/jobs.yml` by running:

```bash
python .github/skills/blog-to-databricks-iac/scripts/azure/generate_jobs_bundle.py \
    --output databricks-bundle/resources/jobs.yml
```

This file is a generated artifact. Keep the source of truth in the generator script, not in manual edits to `jobs.yml`.

### 8. Generate README and TODO from templates

Use the templates in `.github/skills/blog-to-databricks-iac/templates/`:
- `README.md.template` -> `README.md`
- `TODO.md.template` -> `TODO.md`

`TODO.md.template` is a stencil. It carries the five required sections, the entry-field contract, and *universal entries* — actions that apply to every Azure-Databricks deployment from this orchestrator regardless of the source blog (RBAC roles, GitHub Environment setup, secret-scope wiring, the runtime-secrets concept, the Unity Catalog privilege model, state-management decisions, etc.). The template explains each universal entry in enough conceptual depth that a reader unfamiliar with the stack can act on it.

Per-workload entries — the *specifics* that change per blog (which keys, which catalogs, which consumers) — are added by this step from `SPEC.md`. Comment guides in the template show where these go and what shape they take.

#### Entry-field contract

Every entry uses the following fields:

- **Heading** — the action or object in plain language.
- **What this is** (include when the heading does not stand alone) — a short paragraph defining the object or action and its role in the system. Use this whenever a reader unfamiliar with the stack would not know what the heading refers to or how it relates to other generated artifacts. Always include for entries that name an object or wiring (secret scopes, secrets, grants, jobs); often omitted for entries that name a simple value (workflow inputs, RBAC roles).
- **Why deferred** — why the orchestrator did not handle this. Prefer conceptual explanations ("requires the workspace to already exist") over procedural ones ("Step 6 of the skill says so").
- **Source** — pointer to where the requirement originated: a `SPEC.md` section, a SKILL.md step, or a skill name.
- **Resolution** — the steps to take, described as concepts and decisions. Numbered. The reader should know enough to find the right tool and act.
- **Done looks like** (include when the success state isn't obvious from the Resolution) — an assertion the reader can verify after acting.

#### Prohibition on commands and code

Resolutions describe the operator's task in conceptual terms. They do not include shell commands, `az` invocations, `terraform` invocations, `databricks` CLI calls, code snippets, or any other copy-pasteable text.

If a specific tool, UI, or CLI is the natural way to perform a step, name the tool ("the Databricks CLI", "the workspace UI under Settings → Secret scopes", "an `az role assignment` command"). Do not write the command itself. The goal is that an operator who knows the tools can act; an operator who does not know the tools should learn them from the tool's own documentation, not from the TODO.

This rule keeps the file durable: command syntax ages, but conceptual descriptions of what a step is for and how it wires to the rest of the system do not.

#### Rules for `TODO.md`
- The five sections (`Pre-deployment`, `Deployment-time inputs`, `Post-infrastructure`, `Post-DAB`, `Architectural decisions deferred`) are always present, even if a section ends up empty.
- Every entry follows the entry-field contract above.
- Substitute every `{...}` placeholder with the corresponding value from `## Inputs`.
- The `<YOUR_*>` form (e.g. `<YOUR_CLIENT_ID>`) marks values the deployer fills in at run time. Do not substitute these at Step 8 — leave them as-is so the reader knows they are inputs to provide.
- For each `not stated in article` entry in `SPEC.md`, add a corresponding entry to one of: `Pre-deployment`, `Deployment-time inputs`, or `Architectural decisions deferred`. Use the `<from SPEC.md § ...>` shape shown in the template.
- For workload-specific work, add per-workload entries under `Post-infrastructure` and `Post-DAB` using the comment guides as templates. Reference `SPEC.md` sections for workload-specific names rather than embedding them in the entry.
- Per-workload entries follow the same entry-field contract as universal entries, including the same prohibition on commands.
- Remove the HTML comment guides (`<!-- ... -->`) from the output.
- Do not include credentials, connection strings, subscription IDs, or any secret values.
- Do not leave any `{placeholder}` or `<from SPEC.md § ...>` slots unresolved. (`<YOUR_*>` slots are intentional and are kept as-is.)

#### Rules for `README.md`

- Do not leave unresolved placeholders in output.
- Do not include credentials, connection strings, or subscription IDs.

### 9. Validate output before declaring generation complete

This step has three parts. All of it must pass before the skill reports completion.

#### 9.1 Acceptance criteria

The generated output must satisfy the following properties. Each is paired with the verification in 9.2 that proves it.

| # | Criterion | Verified by |
|---|---|---|
| A | DAB is syntactically valid and uses placeholders for values that could not be determined from the article. | 9.2.3 (YAML parse), 9.2.4 (generator runtime) |
| B | `TODO.md` contains only unresolved values and post-deployment actions — no duplication of content that appears in `README.md` or `SPEC.md`. | 9.2.6 (manual inspection) |
| C | Concerns are separated: no Terraform resources defined inside the DAB, no Databricks jobs or notebooks defined inside Terraform. | 9.2.6 (manual inspection) |
| D | Generated code is not production-ready. No fictional resource IDs, no placeholder subscription IDs, no `example.com` hostnames. Every assumption made by the skill is recorded in `TODO.md` or `SPEC.md`. | 9.2.6 (manual inspection) |
| E | Architectural invariants from 9.3 hold for every relevant generated file. | 9.2.5 (invariant checks) |

#### 9.2 Verification commands

#### 9.2 Verification commands

Report pass/fail for each. If any required check fails, stop and report the failures; do not archive until they are resolved.

1. **Python compile.** Run `python -m py_compile` on every generator script, the DAB deploy bridge script, and every medallion Python script.
2. **Terraform static checks.**
   - `terraform -chdir=infra/terraform init -backend=false`
   - `terraform -chdir=infra/terraform validate`
3. **YAML parse.** Parse every file under `.github/workflows/` and every `*.yml` file under `databricks-bundle/` using a YAML parser. Any parse error is a failure.
4. **Generator runtime.** Execute each workflow generator and confirm file regeneration succeeds without error and produces a non-empty file.
5. **Invariant checks.** Run the automated checks in 9.3. Two parity checks must pass; run both explicitly:

```bash
   bash .github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh
   bash .github/skills/blog-to-databricks-iac/scripts/validate_bundle_parity.sh
```

   The first asserts every required variable in `variables.tf` has a matching `TF_VAR_*` export in `deploy-infrastructure.yml`, and that every `terraform apply` invocation uses `-input=false`. The second asserts every `--var name=value` flag emitted by `deploy_dab.py` has a matching declaration under `variables:` in `databricks-bundle/databricks.yml` or any file matched by its `include:` glob, and vice versa.

   Each item marked "validation-time" in 9.3 must have a corresponding check here. If you add a new validation-time invariant, extend an existing script or add a new one and reference it here.
6. **Manual inspection.** Confirm criteria B, C, and D from 9.1 by reading the generated files. Record findings in the execution record (step 10).
7. **Functional test (optional, environment-permitting).** Run the end-to-end medallion flow via the orchestrator job. Verify Bronze, Silver, and Gold target tables are created or updated. If the run is blocked by environment prerequisites, document exactly what is missing in `TODO.md` and mark this check as deferred — do not mark it failed.

#### 9.3 Architectural invariants

Each invariant is labelled by where it is enforced: **generation-time** means the relevant generator or template must produce code that satisfies it and validation does not re-check it; **validation-time** means 9.2 must contain a check that proves the invariant holds on the generated output.

Workflow and credentials (validation-time):
- Every required variable declared in `infra/terraform/variables.tf` (no `default`) has a corresponding `TF_VAR_<name>` export in the Terraform Apply step of `.github/workflows/deploy-infrastructure.yml`.
Check: extract required variable names from `variables.tf`; assert each appears as `TF_VAR_<name>:` in the workflow. Failure mode if missing: `terraform apply` falls back to interactive prompts in CI and hangs until runner timeout.
- Every `terraform apply` invocation in `.github/workflows/deploy-infrastructure.yml` includes `-input=false`.
Check: `grep -E "terraform .* apply" .github/workflows/deploy-infrastructure.yml | grep -v "input=false"` — expected: no output (every apply has the flag).
- The workflow's failure-handling block fast-fails on configuration errors before retry logic engages.
Check: `grep -E "No value for required variable" .github/workflows/deploy-infrastructure.yml` — expected: at least one match in a guard that exits immediately.

Terraform (validation-time):
- `outputs.tf` exports both `databricks_workspace_url` and `databricks_workspace_resource_id`.
  Check: `grep -E '(databricks_workspace_url|databricks_workspace_resource_id)' infra/terraform/outputs.tf` — expected: both names appear.
- When `layer_sp_mode=existing`, Terraform contains no Graph-dependent principal lookups.
  Check: `grep -rE 'data[[:space:]]+"azuread_' infra/terraform/` — expected: no matches.
- AzureRM provider's `features.key_vault.recover_soft_deleted_key_vaults` is driven by a Terraform variable (e.g. `var.key_vault_recover_soft_deleted`), not hardcoded.
  Check: `grep -A 5 'features {' infra/terraform/providers.tf | grep recover_soft_deleted_key_vaults` — expected: the line references `var.`, not a literal `true`/`false`.

DAB bundle (validation-time):
- `databricks-bundle/databricks.yml` includes `resources/*.yml`. Check: grep for `include:` followed by `resources/*.yml`.
- `databricks-bundle/resources/jobs.yml` was produced by `generate_jobs_bundle.py` in this run (not hand-edited). Check: compare file hash to the generator output.
- Every `spark_python_task.python_file` in `jobs.yml` is a relative path from the resources file location (e.g. `../src/<layer>/main.py`). Check: parse `jobs.yml` and verify every python_file entry starts with `../`.
- Every Spark task in `jobs.yml` defines compute via exactly one of `job_cluster_key`, `existing_cluster_id`, `new_cluster`, or `environment_key`. Check: parse `jobs.yml` and assert exactly-one.

DAB bundle (generation-time, enforced by leaf skills):
- DAB layer scripts do not hardcode environment-specific table paths; catalog and schema are passed via task parameters. (Enforced by the `python-entrypoints` skill.)
- `targets.<env>.workspace` in `databricks.yml` contains only schema-supported fields; Databricks Azure auth context is set via environment variables in the deploy bridge, not in the bundle config. (Enforced by the `databricks-yml-authoring` skill.)

Deploy workflow (generation-time, enforced by deploy-infrastructure generator):
- `key_vault_recovery_mode` input accepts `auto`, `recover`, `fresh`, and auto-detection uses `az keyvault list-deleted`.

TODO.md (validation-time):
- `TODO.md` contains all five required sections.
  Check: `for s in "Pre-deployment" "Deployment-time inputs" "Post-infrastructure" "Post-DAB" "Architectural decisions deferred"; do grep -q "^## $s\$" TODO.md || { echo "Missing section: $s"; exit 1; }; done`
- No HTML comment guides remain in the output.
  Check: `grep -E '<!--' TODO.md` — expected: no matches.
- No `{...}` or `<...>` placeholder slots remain unresolved.
  Check: `grep -E '\{[a-z_]+\}|<from SPEC\.md|<runtime_value_not_stated>' TODO.md` — expected: no matches.
- Every `not stated in article` entry in `SPEC.md` is reflected in `TODO.md`.
  Check: count `not stated in article` occurrences in `SPEC.md` and the count of `Source: SPEC.md` references in `TODO.md`; the latter should equal or exceed the former. (Manual inspection acceptable.)

### 10. Archive execution record

After validation completes, create `.github/prompts/plan-blogToDatabricksIac-YYYY-MM-DD-HHmmss.prompt.md` (timestamp reflects run start).

Contents:
- Resolved Inputs (workload, environment, region, github_environment, secret names, `layer_sp_mode`)
- Source blog URL and fetch timestamp
- Path to SPEC.md and summary of architecture decisions
- List of generated artifacts with relative paths
- Validation results: which checks from step 9 passed, which were skipped, and why
- Unresolved items deferred to TODO.md (counts and section headings).

Rules:
- No YAML frontmatter in the file.
- Timestamp format: `YYYY-MM-DD-HHmmss`, UTC, reflecting run start.
- Retain only the 3 most recent prompt files in `.github/prompts/` by filename timestamp; delete older ones.
- Do not include credentials, secret values, or subscription IDs.
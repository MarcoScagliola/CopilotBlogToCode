---
name: databricks-yml-authoring
description: "Author or update the databricks.yml file for a Databricks Asset Bundle. Use when creating, replacing, or modifying databricks.yml — including bundle name, include directives, variables, workspace configuration, and targets. Enforces DAB constraints on fields that do not support any form of interpolation (workspace.host, workspace.profile, workspace.auth_type, bundle.name), the root_path uniqueness rule under mode: development, and requires full-file replacement rather than appending."
---

# databricks.yml Authoring

## Purpose
This skill governs the authoring of a single file: the bundle's `databricks-bundle/databricks.yml`.

It is a companion to the broader `databricks-asset-bundle` skill. Use this skill whenever the task touches `databricks-bundle/databricks.yml` specifically. Use the broader skill for resource files, Python entrypoints, and end-to-end parameter flow.

The path to `databricks-bundle/databricks.yml` depends on the repository layout. Do not assume a fixed location — follow the repo's existing structure.

## Singleton Rule
`databricks-bundle/databricks.yml` is a singleton artifact. No top-level key (`bundle`, `include`, `variables`, `workspace`, `targets`, `resources`, `sync`, `artifacts`, `permissions`, `run_as`, `presets`) may appear more than once.

When re-authoring this file:
1. Always replace the entire file. Never append to it.
2. Before writing, discard the previous contents rather than merging.
3. After writing, scan the output and fail if any top-level key appears more than once.

A file with duplicated top-level keys silently breaks deploys even when the parser tolerates it.

## Fields That Do Not Support Any Interpolation
The Databricks CLI resolves a small set of fields before any interpolation. **No `${...}` expression of any kind** — `${var.*}`, `${bundle.*}`, `${env.*}`, or any other — is permitted in these fields. The CLI fails with errors such as `invalid character "{" in host name` or `Interpolation is not supported for the field <name>`. Treat these as literals only:

- `bundle.name`
- `workspace.host`
- `workspace.profile`
- `workspace.auth_type`

Throughout this skill, these are referred to collectively as **non-interpolable fields**. The three `workspace.*` entries are also referred to as **auth fields** when the discussion is specific to authentication-time resolution. `bundle.name` shares the no-interpolation rule for a different reason: the bundle name forms part of the state path, and dynamic names corrupt state tracking.

Every other field in the bundle supports `${var.*}` interpolation normally, including `workspace.root_path`, which DOES support `${...}` expressions and is governed by a separate rule (see "The `root_path` and `mode: development` Rule" below).

Implications:

**For `bundle.name`:** use a plain literal string. Do not encode environment, workload code, target name, or any `${...}` expression. Environment separation is the job of `targets:`, not the bundle name. Changing the name later orphans existing bundle state.

**For `workspace.host` and other auth fields:** choose one of these patterns:

1. **Omit the field entirely from YAML.** The Databricks CLI reads `DATABRICKS_HOST`, `DATABRICKS_TOKEN`, etc. from the process environment directly. **Do not reference these env vars in YAML via `${env.*}`** — auth-field interpolation is forbidden regardless of the interpolation type. The deploy bridge must `export DATABRICKS_HOST=...` (or equivalent) before invoking `databricks bundle deploy`. Preferred when the host is produced by an upstream system such as infrastructure-as-code output.
2. Hardcode a literal value per target under `targets.<env>.workspace:`.
3. Hardcode a literal value at the top level when there is a single environment.

Never write `workspace.host: ${var.*}`, `workspace.host: ${env.*}`, or any other interpolation form. If a task description implies dynamic host selection, the answer is always one of the three patterns above.

### Examples for `workspace.host`

**Forbidden:**
```yaml
workspace:
  host: ${var.workspace_host}              # ${var.*} interpolation
  host: "https://${env.DATABRICKS_HOST}"   # ${env.*} interpolation
  host: ${bundle.target}-workspace.url     # ${bundle.*} interpolation
```

**Allowed:**
```yaml
# Pattern 1 — omit entirely (preferred when host comes from upstream)
workspace:
  # host field intentionally omitted; CLI reads DATABRICKS_HOST from env

# Pattern 2 — literal per target
targets:
  dev:
    workspace:
      host: https://adb-1234567890.12.azuredatabricks.net

# Pattern 3 — literal at top level (single-environment bundles only)
workspace:
  host: https://adb-1234567890.12.azuredatabricks.net
```

## The `root_path` and `mode: development` Rule

When a target uses `mode: development`, any custom `workspace.root_path` (whether declared at the top level or under that target) MUST include a user-uniqueness marker. The Databricks CLI enforces this with the error:

> `root_path must start with '~/' or contain the current username to ensure uniqueness when using 'mode: development'`

The rule exists to prevent multiple developers — or multiple CI runs under the same principal — from clobbering each other's deployments in the workspace's `/Workspace/Users/...` tree.

### Accepted uniqueness markers

- `~/` at the start of the path (the CLI substitutes the current user's home folder)
- `${workspace.current_user.userName}` anywhere in the path (interpolatable; this is not an auth field)
- `${workspace.current_user.short_name}` (alternative shorter form)

### Decision: which mode for CI deployments

CI deployments driven by a service principal are arguably production by intent, even if the target is named `dev`. Two patterns are valid:

**Pattern A — keep `mode: development`, include the username marker:**
```yaml
targets:
  dev:
    mode: development
    workspace:
      root_path: /Workspace/Users/${workspace.current_user.userName}/.bundle/${bundle.name}/${bundle.target}
```

Pro: preserves development-mode behaviors (auto-paused schedules, notebook source format defaults, deployment tagging). Con: the SP's `userName` becomes part of the path; rotating the SP changes the deploy location.

**Pattern B — switch CI targets to `mode: production`:**
```yaml
targets:
  dev:
    mode: production
    workspace:
      root_path: /Workspace/Shared/.bundle/${bundle.name}/${bundle.target}
```

Pro: stable path independent of SP identity; predictable for shared CI workflows. Con: loses `mode: development` conveniences; need to manage schedule pausing and notebook formats explicitly.

When the deploy is CI-driven by a service principal and the target represents a shared environment, prefer Pattern B. When the deploy represents individual-developer iteration from a laptop, prefer the default `mode: development` with no custom `root_path` at all (which the CLI handles automatically).

### Default behavior — omit `root_path`

The simplest correct option is to omit `workspace.root_path` entirely. The CLI uses a sensible default (`~/.bundle/<bundle-name>/<target>`) that already includes the `~/` uniqueness marker. Only add a custom `root_path` when there's a specific reason to override the default.

## Conventional Structure
Every `databricks.yml` this skill produces follows the conventional shape below. Only `bundle:` is strictly required; `include:`, `variables:`, and `targets:` are conventional and present in most real bundles. Other top-level blocks are optional and may be added when the task requires them, subject to the singleton rule.

```yaml
bundle:                            # required
  name: <literal-string>

include:                           # optional, but typical
  - <glob-matching-resource-files>

variables:                         # optional, present whenever the bundle needs runtime values
  <var_name>:
    description: <text>
    # default: only when a safe env-agnostic default exists

targets:                           # optional, but required in practice for any non-trivial bundle
  <target_name>:
    mode: development | production
    # default: true on at most one target
    # workspace: literal host here if not using env var, and root_path with username marker if mode: development
    # variables: target-specific overrides here when needed
```

`workspace:`, `resources:`, `artifacts:`, `sync:`, `permissions:`, `run_as:`, and `presets:` blocks are optional and may be added when the task requires them, subject to the singleton rule.

Things that must not appear in `databricks-bundle/databricks.yml`:
- `resources.jobs` set to a string file path — `resources.jobs` must be a map of job definitions. Use `include:` to bring in external resource files.
- Any top-level key appearing more than once.
- Secrets, tokens, connection strings, or other sensitive values.
- Any `${...}` expression inside a non-interpolable field.
- A custom `workspace.root_path` that lacks a user-uniqueness marker when any consuming target uses `mode: development`.

## Authoring Procedure
Follow these steps in order.

### Step 1. Identify the bundle name
Pick a stable literal identifier for the workload. Do not embed environment, workload code, or `${...}` expressions.

### Step 2. Decide how resource files are included
If the repo uses separate resource files (the common case), declare an `include:` list whose globs or paths match the repo's actual layout. The skill does not prescribe a specific glob — follow the repository convention.

Never replace `include:` with a `resources.jobs: <path>` string; that pattern is invalid.

### Step 3. Enumerate variables
Collect the full list of runtime values the bundle needs.

Sources, in order of authority:

1. **The deploy bridge.** Whichever script invokes `databricks bundle deploy --var name=value` is the canonical source for the subset of variables that must be declared. The current deploy bridge is `.github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py`. Every `--var` flag that script emits must appear under `variables:` in this file. The Databricks CLI rejects any undeclared `--var` with the error `variable <name> has not been defined`, which fails the deploy.

2. **Resource files.** Every `${var.<name>}` reference in any file matched by the `include:` glob must be declared here. A typo here fails the deploy at resolve time.

3. **Runtime entrypoints.** Arguments consumed by argparse in entrypoints are a separate concern. The mapping between a bundle variable and an entrypoint argument is made explicit in the resource file (see Step 5), so the variable name and the argparse flag need not match.

Rules:
1. One spelling per concept. Do not declare both `catalog` and `catalog_name` for the same value.
2. Provide `default:` only for values that are genuinely environment-agnostic. Do not default environment-specific values — this produces silent misconfiguration when a target forgets to override.
3. Do not declare variables that nothing downstream references. Dead variables mislead readers.
4. **Do not declare a variable whose only purpose is to populate an auth field** (e.g. a `workspace_host` variable when the deploy model uses `DATABRICKS_HOST`). Because auth fields cannot interpolate any expression, such a variable has no legitimate consumer. Authentication values must flow through environment variables set by the deploy bridge, not through bundle variables.
5. Every variable needs a `description:`.
6. **Per-layer variable families MUST be enumerated explicitly per layer.** Declaring one layer's variable does not cause sibling layers to be inferred. If the architecture defines layers (bronze/silver/gold, raw/curated/serving, or any other naming), every per-layer variable must be declared once per layer, by name. The model is prone to declaring three or four of a per-layer family and silently missing the fifth, because the families share a naming pattern and the omission is not visually obvious.

   When the architecture uses distinct identities per data layer, the per-layer variable families typically required are:

   - `<layer>_catalog` — Unity Catalog catalog name
   - `<layer>_schema` — Unity Catalog schema name
   - `<layer>_storage_account` — ADLS Gen2 storage account name
   - `<layer>_access_connector_id` — Azure resource ID of the Databricks Access Connector
   - `<layer>_principal_client_id` — application (client) ID of the layer Service Principal

   Before finishing Step 3, enumerate the layer set, enumerate the families, and verify that the cartesian product appears under `variables:`. A family that is declared for some layers but not others is the most common failure mode this rule prevents.

   Variable descriptions for `*_principal_client_id` entries MUST say "application (client) ID of the <layer> Service Principal", not just "client ID". The operator-facing distinction between application ID and object ID, and between App Registration and Service Principal, is load-bearing elsewhere in the deployment contract and the variable description is where it gets reinforced.

### Step 4. Define targets
Declare at least one target. The set and names depend on the repo (commonly `dev`, `test`, `prd`, but `staging`/`prod`, per-developer sandboxes, and other schemes are valid).

Rules:
1. Set `default: true` on at most one target — typically the lowest-risk environment — so that `databricks bundle deploy` without `--target` is safe.
2. Use `mode: development` or `mode: production` as appropriate. These enable different CLI behaviors.
3. Put target-specific variable values under `targets.<name>.variables:` only when they are truly static per environment. When values come from an upstream system, prefer passing them via the deploy bridge so that the bundle file itself stays environment-agnostic.
4. If the deploy model uses `DATABRICKS_HOST` (preferred), no per-target host configuration is needed in this file. If using hardcoded per-target hosts instead, place a literal URL under `targets.<name>.workspace.host:`. Never use any `${...}` expression here.
5. **`root_path` and `mode: development` interaction.** When a target uses `mode: development`, any custom `workspace.root_path` MUST include either `~/` or `${workspace.current_user.userName}`. The CLI rejects mismatches at deploy time. If the deployment is CI-driven by a service principal targeting a shared environment, consider `mode: production` with an explicit shared `root_path` instead — `mode: development` is designed for individual-developer iteration. When in doubt, omit `root_path` entirely; the CLI's default already satisfies the uniqueness rule.

### Step 5. Verify downstream consistency
Two boundaries to check, with different rules at each.

**Hard reference (must spell-match):** the bundle variable name as declared in this file vs. as referenced via `${var.<name>}` in resource files. A mismatch here fails the deploy.

**Explicit mapping (need not spell-match):** the parameter name passed by a resource file to a runtime entrypoint vs. the argparse flag the entrypoint accepts. The mapping is made explicit in the resource file (e.g. `parameters: ["--catalog", "${var.bronze_catalog}"]`), so the bundle variable can be `bronze_catalog` while the entrypoint flag is `--catalog`. What matters is that the chain is unambiguous.

Before writing, confirm:

1. Run the parity check: `scripts/validate_bundle_parity.sh`. The script extracts the set of `--var` names emitted by the deploy bridge and the set of variable names declared in `databricks.yml` plus any included resource files, then diffs the two. The check fails if either set has entries the other does not. This must pass before the file is considered complete.

   If `scripts/validate_bundle_parity.sh` does not exist in the repository, author it before continuing. Its shape is parallel to the existing `scripts/validate_workflow_parity.sh`: extract names from one artifact, extract declared names from another, diff, exit non-zero on any divergence.

2. Every `${var.<name>}` reference in resource files matches a variable declared in this file.
3. The argparse contract of each entrypoint is satisfied by the parameters its resource file passes (mapping is explicit; spellings need not match).

If spellings diverge across the hard-reference boundary, reconcile them to a single canonical form before finishing.

### Step 6. Final validation
After writing, verify:

1. Each top-level key appears at most once.
2. `bundle.name` is a literal string with no `${...}`.
3. **No `${...}` expression of any kind** (`${var.*}`, `${bundle.*}`, `${env.*}`, or any other) appears in any non-interpolable field. The check is: grep for `${` inside the values of `bundle.name`, `workspace.host`, `workspace.profile`, `workspace.auth_type`, including their per-target overrides. Any match fails.
4. `resources.jobs`, if present, is a map and not a string.
5. Every declared variable has a `description:`.
6. Every variable referenced downstream is declared.
6a. `scripts/validate_bundle_parity.sh` exits zero. This is the executable equivalent of items 6 and 7. If the script reports a divergence, the divergence MUST be resolved in this file, not by editing the deploy bridge or by suppressing the script's output.
6b. The interpolation check passes:
```bash
    # All non-interpolable fields must be literals — no ${...} of any kind
    yq '.bundle.name, .workspace.host, .workspace.profile, .workspace.auth_type,
        .targets[].workspace.host, .targets[].workspace.profile, .targets[].workspace.auth_type' \
        databricks-bundle/databricks.yml | grep -E '\$\{' && exit 1 || exit 0
```
    If this exits non-zero, an interpolation has crept into a non-interpolable field.
6c. The `root_path` uniqueness check passes:
```bash
    # For every target with mode: development, any custom root_path must include ~/ or ${workspace.current_user.*}
    yq '.targets | to_entries[] | select(.value.mode == "development") | .value.workspace.root_path // ""' \
        databricks-bundle/databricks.yml | while read -r path; do
      if [ -n "$path" ] && ! echo "$path" | grep -qE '(^~/|\$\{workspace\.current_user)'; then
        echo "Development target has root_path without uniqueness marker: $path"
        exit 1
      fi
    done
```
    Also check the top-level `workspace.root_path` if any target inherits it under `mode: development`.
7. Every declared variable is referenced by something (bridge, resource file, or target override).
8. No declared variable's only apparent consumer is an auth field (which cannot interpolate).
9. `include:` entries match paths that exist in the repo.
10. No secrets or tokens are embedded.

If any check fails, rewrite the file fully rather than patching in place.

## Minimal Template
The following is the smallest correct shape. Adapt variable names, include paths, and target names to the repository.

```yaml
bundle:
  name: <literal-name>

include:
  - <repo-specific-resource-glob>

variables:
  <example_var>:
    description: <what this variable represents>

targets:
  <primary_target>:
    mode: development
    default: true
    # No custom root_path needed — the CLI default includes ~/ automatically.

  <other_target>:
    mode: production
```

If the CI deploy runs under a service principal and targets a shared environment, prefer the production-mode pattern:

```yaml
targets:
  dev:
    mode: production
    default: true
    workspace:
      root_path: /Workspace/Shared/.bundle/${bundle.name}/${bundle.target}
```

## Anti-Patterns to Reject
Reject any proposed change that would produce:

1. **`${...}` of any kind in any non-interpolable field** (`bundle.name`, `workspace.host`, `workspace.profile`, `workspace.auth_type`). This covers `${var.*}`, `${bundle.*}`, `${env.*}`, and any other interpolation syntax. The CLI resolves these fields before interpolation runs, so any expression fails.
2. `resources.jobs` set to a string file path.
3. Any top-level key appearing more than once.
4. Secrets, tokens, or credentials embedded in the file.
5. Environment-specific defaults on variables intended for use across environments.
6. Variables declared with no downstream consumer.
7. Variables whose only apparent purpose is to populate an auth field via interpolation. Authentication values flow through environment variables, never through bundle variables.
8. **Per-layer variable families with missing layers.** If `bronze_principal_client_id` and `silver_principal_client_id` are declared, `gold_principal_client_id` must also be declared. Partial per-layer families are a deploy-time failure waiting to happen.
9. **Custom `root_path` under `mode: development` without a user-uniqueness marker.** The CLI rejects this at deploy time with `root_path must start with '~/' or contain the current username`. Either include `~/` / `${workspace.current_user.userName}` in the path, switch the target to `mode: production`, or omit `root_path` entirely.

## Relationship to Other Skills
- The broader `databricks-asset-bundle` skill owns resource files, runtime entrypoints, job topology, and end-to-end parameter flow. Return to it after `databricks-bundle/databricks.yml` work is complete for any cross-cutting bundle review. This skill defers to it for anything outside `databricks-bundle/databricks.yml`.
- The `python-entrypoints` skill owns the argparse contracts of runtime entrypoints. The mapping between bundle variables here and argparse arguments there is made explicit in resource files; this skill is responsible only for what is declared in `databricks-bundle/databricks.yml`.
- Any script that generates resource files must produce output whose `${var.*}` references are declared in this file.
- Any deploy bridge must pass `--var` names that match the declarations in this file, and is the correct place to export auth-related environment variables (`DATABRICKS_HOST`, `DATABRICKS_TOKEN`, etc.).

## Review Checklist
- [ ] File fully replaced, not appended.
- [ ] Each top-level key appears at most once.
- [ ] `bundle.name` is a literal.
- [ ] **No `${...}` expression of any kind** (`${var.*}`, `${bundle.*}`, `${env.*}`, or any other) in any non-interpolable field (`bundle.name`, `workspace.host`, `workspace.profile`, `workspace.auth_type`).
- [ ] No variable exists solely to populate an auth field.
- [ ] No `resources.jobs: <string>`.
- [ ] Every declared variable has a `description:`.
- [ ] Every declared variable is referenced downstream.
- [ ] Every downstream `${var.*}` reference is declared.
- [ ] `include:` entries match paths that exist in the repo.
- [ ] Auth configuration is handled outside the file (env var exported by deploy bridge, or per-target literal).
- [ ] Deploy bridge `--var` names match this file's variable names.
- [ ] Deploy bridge exports `DATABRICKS_HOST` (and other auth env vars) before invoking the CLI, rather than passing them as `--var`.
- [ ] `scripts/validate_bundle_parity.sh` exists and exits zero.
- [ ] The interpolation check on non-interpolable fields exits zero.
- [ ] For every target with `mode: development`, any custom `workspace.root_path` includes `~/` or `${workspace.current_user.userName}` (or `root_path` is omitted entirely).
- [ ] Every per-layer variable family is declared for every layer the architecture defines (no partial families).
- [ ] No secrets or tokens embedded.
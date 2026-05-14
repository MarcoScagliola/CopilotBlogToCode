---
name: databricks-yml-authoring
description: "Author or update the databricks.yml file for a Databricks Asset Bundle. Use when creating, replacing, or modifying databricks.yml — including bundle name, include directives, variables, workspace configuration, and targets. The targets block has a copy-verbatim shape that overrides pattern memory; see 'Required Shapes for the targets Block' early in this skill. Enforces DAB constraints on fields that do not support any form of interpolation (workspace.host, workspace.profile, workspace.auth_type, bundle.name), the root_path uniqueness rule under mode: development, and requires full-file replacement rather than appending."
---

# databricks.yml Authoring

## Purpose
This skill governs the authoring of a single file: the bundle's `databricks.yml`.

It is a companion to the broader `databricks-asset-bundle` skill. Use this skill whenever the task touches `databricks.yml` specifically. Use the broader skill for resource files, Python entrypoints, and end-to-end parameter flow.

The path to `databricks.yml` depends on the repository layout — commonly `databricks-bundle/databricks.yml` or `bundle/databricks.yml`, but follow the repo's existing structure. Throughout this skill, paths shown in validation snippets use `<bundle-dir>` as a placeholder; substitute the actual location.

## Required Shapes for the `targets` Block

**This section is positioned early because the `targets:` block is the most regression-prone part of this file.** When generating under cognitive load, models tend to pattern-match on familiar Databricks bundle examples and emit a `host:` line that violates the no-interpolation rule. The fix is structural: don't reason about what to put in `targets:`. Pick one of the shapes below and copy it, then fill in the names.

### Shape A — CI deployment via service principal (default for non-developer deploys)

When the deploy is invoked by a service principal in a workflow (any CI-driven deploy), copy this exact shape:

```yaml
targets:
  <env-name>:
    default: true
    mode: production
    workspace:
      root_path: <stable-path-without-username>/.bundle/${bundle.name}/${bundle.target}
  <other-env-name>:
    mode: production
    workspace:
      root_path: <stable-path-without-username>/.bundle/${bundle.name}/${bundle.target}
```

`default: true` appears on exactly one target across the file (typically the lowest-risk environment).

`<stable-path-without-username>` is a workspace folder the deploying principal can write to and that does not contain a per-user component. `/Workspace/Shared` is a common choice for cross-team CI; some repos prefer `/Workspace/<workload-name>` or `/Workspace/CI`. The path itself is a repo decision — what matters is that it is stable across runs and does not embed the service principal's username.

What is **NOT** in this shape, and must not be added:
- No `host:` field anywhere.
- No `${env.DATABRICKS_HOST}`.
- No `${var.workspace_host}`.
- No literal workspace URL.

The Databricks CLI reads `DATABRICKS_HOST` from the process environment, set by the deploy bridge before invocation. The bundle file MUST NOT reference that environment variable in YAML — interpolation is rejected by the CLI on auth fields.

### Shape B — Individual developer iteration from a laptop

When the deploy is invoked by a human running `databricks bundle deploy` locally, copy this shape:

```yaml
targets:
  <env-name>:
    default: true
    mode: development
```

No `workspace:` block at all. The CLI's default `root_path` of `~/.bundle/<bundle-name>/<target>` is used automatically.

### Rule of last resort

If about to emit ANY `workspace.host` line, STOP. Re-read this section. Pick Shape A or Shape B and copy it. There is no third option. Custom hosts go through `DATABRICKS_HOST` env var, set by the deploy bridge, never in the YAML.

The rest of this skill explains the *why* behind these shapes and provides validation rules. If the emitted `targets:` block matches Shape A or Shape B, most of the rules below are already satisfied.

## Singleton Rule
`databricks.yml` is a singleton artifact. No top-level key (`bundle`, `include`, `variables`, `workspace`, `targets`, `resources`, `sync`, `artifacts`, `permissions`, `run_as`, `presets`) may appear more than once.

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

**For `workspace.host` and other auth fields:** if reasoning about what to put in `workspace.host`, the planning step has skipped "Required Shapes for the targets Block" above. Go back, pick Shape A or Shape B, copy it verbatim.

For reference, the only ways `workspace.host` can be set are:

1. **Omit the field entirely from YAML** (Shape A and Shape B both do this). The Databricks CLI reads `DATABRICKS_HOST` from the process environment directly. **Do not reference these env vars in YAML via `${env.*}`** — auth-field interpolation is forbidden regardless of the interpolation type.
2. Hardcode a literal value per target under `targets.<env>.workspace.host:` (only when the workspace URL is known at authoring time and will never change).
3. Hardcode a literal value at the top level when there is a single environment.

Never write `workspace.host: ${var.*}`, `workspace.host: ${env.*}`, or any other interpolation form.

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
# Pattern 1 — omit entirely (Shape A and Shape B do this)
workspace:
  # host field intentionally omitted; CLI reads DATABRICKS_HOST from env

# Pattern 2 — literal per target (only when URL is known at authoring time)
targets:
  dev:
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

### Why Shape A uses `mode: production` for CI

CI deployments driven by a service principal are production by intent, even if the target is named `dev`. `mode: development` is designed for individual-developer iteration from a laptop, where the developer's `userName` is meaningful in the path. For a service principal, that path becomes brittle — rotating the SP changes the deploy location.

Shape A uses `mode: production` with a stable `root_path` that does not embed the username. This is the right choice for CI-driven deploys.

If a CI deploy must use `mode: development` for some reason, the only valid pattern is:

```yaml
targets:
  dev:
    mode: development
    workspace:
      root_path: /Workspace/Users/${workspace.current_user.userName}/.bundle/${bundle.name}/${bundle.target}
```

But the default and recommended approach for CI is Shape A.

### Default behavior — omit `root_path`

For Shape B (laptop development), omit `workspace.root_path` entirely. The CLI uses a sensible default (`~/.bundle/<bundle-name>/<target>`) that already includes the `~/` uniqueness marker.

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

targets:                           # see "Required Shapes for the targets Block" above
  # Use Shape A for CI deploys, Shape B for laptop development.
```

`workspace:`, `resources:`, `artifacts:`, `sync:`, `permissions:`, `run_as:`, and `presets:` blocks are optional and may be added when the task requires them, subject to the singleton rule.

Things that must not appear in `databricks.yml`:
- `resources.jobs` set to a string file path — `resources.jobs` must be a map of job definitions. Use `include:` to bring in external resource files.
- Any top-level key appearing more than once.
- Secrets, tokens, connection strings, or other sensitive values.
- Any `${...}` expression inside a non-interpolable field.
- A custom `workspace.root_path` that lacks a user-uniqueness marker when any consuming target uses `mode: development`.
- A `targets:` block that does not match Shape A or Shape B from "Required Shapes for the targets Block."

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

1. **The deploy bridge script.** Whichever script invokes `databricks bundle deploy --var name=value` is the canonical source for the subset of variables that must be declared. Every `--var` flag the bridge emits must appear under `variables:` in this file. The Databricks CLI rejects any undeclared `--var` with the error `variable <name> has not been defined`, which fails the deploy.

2. **Resource files.** Every `${var.<name>}` reference in any file matched by the `include:` glob must be declared here. A typo here fails the deploy at resolve time.

3. **Runtime entrypoints.** Arguments consumed by argparse in entrypoints are a separate concern. The mapping between a bundle variable and an entrypoint argument is made explicit in the resource file (see Step 5), so the variable name and the argparse flag need not match.

Rules:
1. One spelling per concept. Do not declare both `catalog` and `catalog_name` for the same value.
2. Provide `default:` only for values that are genuinely environment-agnostic. Do not default environment-specific values — this produces silent misconfiguration when a target forgets to override.
3. Do not declare variables that nothing downstream references. Dead variables mislead readers.
4. **Do not declare a variable whose only purpose is to populate an auth field** (e.g. a `workspace_host` variable when the deploy model uses `DATABRICKS_HOST`). Because auth fields cannot interpolate any expression, such a variable has no legitimate consumer. Authentication values must flow through environment variables set by the deploy bridge, not through bundle variables.
5. Every variable needs a `description:`.
6. **Per-instance variable families MUST be enumerated explicitly per instance.** When the architecture defines repeated instances (per-layer, per-environment, per-tenant, per-region, or any other dimension), every per-instance variable must be declared once per instance, by name. Models are prone to declaring three or four of a per-instance family and silently missing the fifth, because the families share a naming pattern and the omission is not visually obvious.

   For example, a three-layer medallion architecture with per-layer service principals will need `<layer>_principal_client_id` declared for each of bronze, silver, and gold. Declaring two of the three and assuming the third will follow is a deploy-time failure waiting to happen.

   Before finishing Step 3, enumerate the instance set, enumerate the variable families, and verify that the cartesian product appears under `variables:`.

7. **Variable descriptions disambiguate identity-ID variants when relevant.** When a deployment uses multiple ID variants for the same logical entity (e.g. application ID vs object ID, client ID vs principal ID), variable descriptions should make the distinction explicit. Operators reading the variable list should be able to tell from the description which ID variant the bridge will pass.

### Step 4. Define targets

Go to "Required Shapes for the targets Block" at the top of this skill. Pick Shape A (CI deployment, default) or Shape B (laptop development). Copy the chosen shape verbatim. Fill in `<env-name>`, `<other-env-name>`, and `<stable-path-without-username>` with values appropriate for the repo.

Do not improvise. Do not add a `host:` field. Do not "complete" the shape with workspace metadata that the shape intentionally omits.

The rules below apply for additional configuration beyond what Shape A or Shape B provides:

1. `default: true` appears on at most one target across the file (typically the lowest-risk environment).
2. Target-specific variable values under `targets.<name>.variables:` only when they are truly static per environment. Values from upstream systems flow through the deploy bridge, not through static target overrides.

### Step 5. Verify downstream consistency
Two boundaries to check, with different rules at each.

**Hard reference (must spell-match):** the bundle variable name as declared in this file vs. as referenced via `${var.<name>}` in resource files. A mismatch here fails the deploy.

**Explicit mapping (need not spell-match):** the parameter name passed by a resource file to a runtime entrypoint vs. the argparse flag the entrypoint accepts. The mapping is made explicit in the resource file (e.g. `parameters: ["--catalog", "${var.bronze_catalog}"]`), so the bundle variable can be `bronze_catalog` while the entrypoint flag is `--catalog`. What matters is that the chain is unambiguous.

Before writing, confirm:

1. Run the bundle parity check script if one exists in the repository. The script extracts the set of `--var` names emitted by the deploy bridge and the set of variable names declared in `databricks.yml` plus any included resource files, then diffs the two. The check fails if either set has entries the other does not. This must pass before the file is considered complete.

   If no such script exists, author one. Its shape is: extract names from one artifact, extract declared names from another, diff, exit non-zero on any divergence. Common name is `validate_bundle_parity.sh` or similar.

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
7. **The `targets:` block matches Shape A or Shape B from "Required Shapes for the targets Block."** Specifically:
   - No `host:` field appears anywhere under `targets:`.
   - Every target has a `mode:` field set to either `production` or `development`.
   - `default: true` appears on exactly one target.
8. The bundle parity check script exits zero. This is the executable equivalent of items 5 and 6 above. If the script reports a divergence, the divergence MUST be resolved in this file, not by editing the deploy bridge or by suppressing the script's output.
9. The interpolation check passes (run from repo root, substituting the actual file path):

```bash
   # No ${...} should appear in a host: line anywhere in the file
   grep -nE 'host:\s*.*\$\{' <bundle-dir>/databricks.yml && exit 1 || echo "OK"
```

   If this prints any line, the interpolation rule has been violated; the file must be regenerated.

10. The `root_path` uniqueness check passes:

```bash
    # For every mode: development target, root_path (if present) includes a uniqueness marker.
    awk '/mode:[[:space:]]*development/,/^[a-z]/' <bundle-dir>/databricks.yml | \
      grep -E '^\s*root_path:' | \
      grep -vE '(~/|\$\{workspace\.current_user)' && exit 1 || echo "OK"
```

    If this prints a line, a `mode: development` target has a non-compliant `root_path` and must be corrected.

11. Every declared variable is referenced by something (bridge, resource file, or target override).
12. No declared variable's only apparent consumer is an auth field (which cannot interpolate).
13. `include:` entries match paths that exist in the repo.
14. No secrets or tokens are embedded.

If any check fails, rewrite the file fully rather than patching in place.

## Anti-Patterns to Reject
Reject any proposed change that would produce:

1. **`${...}` of any kind in any non-interpolable field** (`bundle.name`, `workspace.host`, `workspace.profile`, `workspace.auth_type`). This covers `${var.*}`, `${bundle.*}`, `${env.*}`, and any other interpolation syntax. The CLI resolves these fields before interpolation runs, so any expression fails.
2. **A `targets:` block that does not match Shape A or Shape B** from "Required Shapes for the targets Block." Any improvised target shape is a regression.
3. `resources.jobs` set to a string file path.
4. Any top-level key appearing more than once.
5. Secrets, tokens, or credentials embedded in the file.
6. Environment-specific defaults on variables intended for use across environments.
7. Variables declared with no downstream consumer.
8. Variables whose only apparent purpose is to populate an auth field via interpolation. Authentication values flow through environment variables, never through bundle variables.
9. **Per-instance variable families with missing instances.** Partial families are a deploy-time failure waiting to happen.
10. **Custom `root_path` under `mode: development` without a user-uniqueness marker.** The CLI rejects this at deploy time with `root_path must start with '~/' or contain the current username`. Either include `~/` / `${workspace.current_user.userName}` in the path, switch the target to `mode: production`, or omit `root_path` entirely.
11. **A target without an explicit `mode:` field.** Every target must declare its mode (`production` or `development`). Omitting `mode:` produces a target that inherits CLI defaults inconsistently across versions.

## Relationship to Other Skills
- The broader `databricks-asset-bundle` skill owns resource files, runtime entrypoints, job topology, and end-to-end parameter flow. Return to it after `databricks.yml` work is complete for any cross-cutting bundle review. This skill defers to it for anything outside `databricks.yml`.
- The `python-entrypoints` skill owns the argparse contracts of runtime entrypoints. The mapping between bundle variables here and argparse arguments there is made explicit in resource files; this skill is responsible only for what is declared in `databricks.yml`.
- Any script that generates resource files must produce output whose `${var.*}` references are declared in this file.
- Any deploy bridge must pass `--var` names that match the declarations in this file, and is the correct place to export auth-related environment variables (`DATABRICKS_HOST`, `DATABRICKS_TOKEN`, etc.).

## Review Checklist
- [ ] File fully replaced, not appended.
- [ ] Each top-level key appears at most once.
- [ ] `bundle.name` is a literal.
- [ ] **No `${...}` expression of any kind** (`${var.*}`, `${bundle.*}`, `${env.*}`, or any other) in any non-interpolable field (`bundle.name`, `workspace.host`, `workspace.profile`, `workspace.auth_type`).
- [ ] **The `targets:` block matches Shape A or Shape B verbatim** (with placeholders substituted).
- [ ] **No `host:` field appears anywhere under `targets:`.**
- [ ] **Every target has an explicit `mode:` field** (`production` or `development`).
- [ ] `default: true` appears on exactly one target.
- [ ] No variable exists solely to populate an auth field.
- [ ] No `resources.jobs: <string>`.
- [ ] Every declared variable has a `description:`.
- [ ] Every declared variable is referenced downstream.
- [ ] Every downstream `${var.*}` reference is declared.
- [ ] `include:` entries match paths that exist in the repo.
- [ ] Auth configuration is handled outside the file (env var exported by deploy bridge).
- [ ] Deploy bridge `--var` names match this file's variable names.
- [ ] Deploy bridge exports `DATABRICKS_HOST` (and other auth env vars) before invoking the CLI, rather than passing them as `--var`.
- [ ] Bundle parity check script exists and exits zero.
- [ ] The grep check for `${...}` in any `host:` line returns no matches.
- [ ] For every target with `mode: development`, any custom `workspace.root_path` includes `~/` or `${workspace.current_user.userName}` (or `root_path` is omitted entirely).
- [ ] Every per-instance variable family is declared for every instance the architecture defines (no partial families).
- [ ] No secrets or tokens embedded.
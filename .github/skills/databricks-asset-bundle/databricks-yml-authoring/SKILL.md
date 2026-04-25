---
name: databricks-yml-authoring
description: "Author or update the databricks.yml file for a Databricks Asset Bundle. Use when creating, replacing, or modifying databricks.yml — including bundle name, include directives, variables, workspace configuration, and targets. Enforces DAB constraints on fields that do not support variable interpolation (workspace.host, workspace.profile, workspace.auth_type, bundle.name) and requires full-file replacement rather than appending."
---

# databricks.yml Authoring

## Purpose
This skill governs the authoring of a single file: the bundle's `databricks-bundle\databricks.yml`.

It is a companion to the broader `databricks-asset-bundle` skill. Use this skill whenever the task touches `databricks-bundle\databricks.yml` specifically. Use the broader skill for resource files, Python entrypoints, and end-to-end parameter flow.

The path to `databricks-bundle\databricks.yml` depends on the repository layout. Do not assume a fixed location — follow the repo's existing structure.

## Singleton Rule
`databricks-bundle\databricks.yml` is a singleton artifact. No top-level key (`bundle`, `include`, `variables`, `workspace`, `targets`, `resources`, `sync`, `artifacts`, `permissions`, `run_as`, `presets`) may appear more than once.

When re-authoring this file:
1. Always replace the entire file. Never append to it.
2. Before writing, discard the previous contents rather than merging.
3. After writing, scan the output and fail if any top-level key appears more than once.

A file with duplicated top-level keys silently breaks deploys even when the parser tolerates it.

## Fields That Do Not Support Variable Interpolation
The Databricks CLI resolves a small set of fields before variable substitution. `${var.*}` and `${bundle.*}` references in them will fail or be ignored. Treat these as literals only:

- `bundle.name`
- `workspace.host`
- `workspace.profile`
- `workspace.auth_type`

Throughout this skill, these are referred to collectively as **non-interpolable fields**. The three `workspace.*` entries are also referred to as **auth fields** when the discussion is specific to authentication-time resolution. `bundle.name` shares the no-interpolation rule for a different reason: the bundle name forms part of the state path, and dynamic names corrupt state tracking.

Every other field in the bundle supports `${var.*}` interpolation normally.

Implications:

**For `bundle.name`:** use a plain literal string. Do not encode environment, workload code, target name, or any `${...}` expression. Environment separation is the job of `targets:`, not the bundle name. Changing the name later orphans existing bundle state.

**For `workspace.host` and other auth fields:** choose one of these patterns:
1. Omit from YAML and supply via environment variable (`DATABRICKS_HOST`, `DATABRICKS_TOKEN`, etc.). Preferred when the host is produced by an upstream system such as infrastructure-as-code output.
2. Hardcode a literal value per target under `targets.<env>.workspace:`.
3. Hardcode a literal value at the top level when there is a single environment.

Never write `workspace.host: ${var.*}`. If a task description implies dynamic host selection, the answer is always one of the three patterns above.

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
    # workspace: literal host here if not using env var
    # variables: target-specific overrides here when needed
```

`workspace:`, `resources:`, `artifacts:`, `sync:`, `permissions:`, `run_as:`, and `presets:` blocks are optional and may be added when the task requires them, subject to the singleton rule.

Things that must not appear in `databricks-bundle\databricks.yml`:
- `resources.jobs` set to a string file path — `resources.jobs` must be a map of job definitions. Use `include:` to bring in external resource files.
- Any top-level key appearing more than once.
- Secrets, tokens, connection strings, or other sensitive values.

## Authoring Procedure
Follow these steps in order.

### Step 1. Identify the bundle name
Pick a stable literal identifier for the workload. Do not embed environment, workload code, or `${...}` expressions.

### Step 2. Decide how resource files are included
If the repo uses separate resource files (the common case), declare an `include:` list whose globs or paths match the repo's actual layout. The skill does not prescribe a specific glob — follow the repository convention.

Never replace `include:` with a `resources.jobs: <path>` string; that pattern is invalid.

### Step 3. Enumerate variables
Collect the full list of runtime values the bundle needs. Sources typically include:
- any deploy bridge or script that maps upstream values to `--var` flags
- `${var.*}` references in resource files
- arguments consumed by runtime entrypoints

Every variable referenced via `${var.*}` in resource files must be declared here with the same spelling — that is a hard YAML reference and a typo will fail the deploy. Argparse argument names in entrypoints are a separate concern; see Step 5.

Rules:
1. One spelling per concept. Do not declare both `catalog` and `catalog_name` for the same value.
2. Provide `default:` only for values that are genuinely environment-agnostic. Do not default environment-specific values — this produces silent misconfiguration when a target forgets to override.
3. Do not declare variables that nothing downstream references. Dead variables mislead readers.
4. Do not declare a variable that exists only to carry an auth-field value (e.g. a `workspace_host` variable when the deploy model uses `DATABRICKS_HOST`). Because auth fields cannot interpolate, such a variable has no legitimate consumer.
5. Every variable needs a `description:`.

### Step 4. Define targets
Declare at least one target. The set and names depend on the repo (commonly `dev`, `test`, `prd`, but `staging`/`prod`, per-developer sandboxes, and other schemes are valid).

Rules:
1. Set `default: true` on at most one target — typically the lowest-risk environment — so that `databricks bundle deploy` without `--target` is safe.
2. Use `mode: development` or `mode: production` as appropriate. These enable different CLI behaviors.
3. Put target-specific variable values under `targets.<name>.variables:` only when they are truly static per environment. When values come from an upstream system, prefer passing them via the deploy bridge so that the bundle file itself stays environment-agnostic.
4. If the deploy model uses `DATABRICKS_HOST` (preferred), no per-target host configuration is needed in this file. If using hardcoded per-target hosts instead, place a literal URL under `targets.<name>.workspace.host:`.

### Step 5. Verify downstream consistency
Two boundaries to check, with different rules at each.

**Hard reference (must spell-match):** the bundle variable name as declared in this file vs. as referenced via `${var.<name>}` in resource files. A mismatch here fails the deploy.

**Explicit mapping (need not spell-match):** the parameter name passed by a resource file to a runtime entrypoint vs. the argparse flag the entrypoint accepts. The mapping is made explicit in the resource file (e.g. `parameters: ["--catalog", "${var.bronze_catalog}"]`), so the bundle variable can be `bronze_catalog` while the entrypoint flag is `--catalog`. What matters is that the chain is unambiguous.

Before writing, confirm:
1. The `--var <name>=...` flags produced by any deploy bridge match the variable names declared in this file.
2. Every `${var.<name>}` reference in resource files matches a variable declared in this file.
3. The argparse contract of each entrypoint is satisfied by the parameters its resource file passes (mapping is explicit; spellings need not match).

If spellings diverge across the hard-reference boundary, reconcile them to a single canonical form before finishing.

### Step 6. Final validation
After writing, verify:

1. Each top-level key appears at most once.
2. `bundle.name` is a literal string with no `${...}`.
3. No `${var.*}` or `${bundle.*}` appears in any non-interpolable field (`workspace.host`, `workspace.profile`, `workspace.auth_type`, `bundle.name`).
4. `resources.jobs`, if present, is a map and not a string.
5. Every declared variable has a `description:`.
6. Every variable referenced downstream is declared.
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

  <other_target>:
    mode: production
```

## Anti-Patterns to Reject
Reject any proposed change that would produce:

1. `${...}` in any non-interpolable field (`bundle.name`, `workspace.host`, `workspace.profile`, `workspace.auth_type`).
2. `resources.jobs` set to a string file path.
3. Any top-level key appearing more than once.
4. Secrets, tokens, or credentials embedded in the file.
5. Environment-specific defaults on variables intended for use across environments.
6. Variables declared with no downstream consumer.
7. Variables whose only apparent purpose is to populate an auth field via interpolation.

## Relationship to Other Skills
- The broader `databricks-asset-bundle` skill owns resource files, runtime entrypoints, job topology, and end-to-end parameter flow. Return to it after `databricks-bundle\databricks.yml` work is complete for any cross-cutting bundle review. This skill defers to it for anything outside `databricks-bundle\databricks.yml`.
- The `python-entrypoints` skill owns the argparse contracts of runtime entrypoints. The mapping between bundle variables here and argparse arguments there is made explicit in resource files; this skill is responsible only for what is declared in `databricks-bundle\databricks.yml`.
- Any script that generates resource files must produce output whose `${var.*}` references are declared in this file.
- Any deploy bridge must pass `--var` names that match the declarations in this file, and is the correct place to export auth-related environment variables.

## Review Checklist
- [ ] File fully replaced, not appended.
- [ ] Each top-level key appears at most once.
- [ ] `bundle.name` is a literal.
- [ ] No `${var.*}` or `${bundle.*}` in any non-interpolable field (`bundle.name`, `workspace.host`, `workspace.profile`, `workspace.auth_type`).
- [ ] No variable exists solely to populate an auth field.
- [ ] No `resources.jobs: <string>`.
- [ ] Every declared variable has a `description:`.
- [ ] Every declared variable is referenced downstream.
- [ ] Every downstream `${var.*}` reference is declared.
- [ ] `include:` entries match paths that exist in the repo.
- [ ] Auth configuration is handled outside the file (env var or per-target literal).
- [ ] Deploy bridge `--var` names match this file's variable names.
- [ ] No secrets or tokens embedded.
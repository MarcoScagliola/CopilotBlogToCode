---
name: databricks-yml-authoring
description: "Author or update the databricks.yml file for a Databricks Asset Bundle. Use when creating, replacing, or modifying databricks.yml — including bundle name, include directives, variables, workspace configuration, and targets. Enforces DAB constraints on fields that do not support variable interpolation (workspace.host, workspace.profile, workspace.auth_type, bundle.name) and requires full-file replacement rather than appending."
---

# databricks.yml Authoring

## Purpose
This skill governs the authoring of a single file: the bundle's `databricks.yml`.

It is a companion to the broader `databricks-asset-bundle` skill. Use this skill whenever the task touches `databricks.yml` specifically. Use the broader skill for resource files, Python entrypoints, and end-to-end parameter flow.

The path to `databricks.yml` depends on the repository layout. Do not assume a fixed location — follow the repo's existing structure.

## Singleton Rule
`databricks.yml` is a singleton artifact. Every top-level key (`bundle`, `include`, `variables`, `workspace`, `targets`, `resources`, `sync`, `artifacts`, `permissions`, `run_as`, `presets`) must appear at most once, and when present must appear exactly once.

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

Every other field in the bundle supports `${var.*}` interpolation normally.

Implications:

**For `bundle.name`:** use a plain literal string. Do not encode environment, workload code, target name, or any `${...}` expression. Environment separation is the job of `targets:`, not the bundle name. Changing the name later orphans existing bundle state.

**For `workspace.host` and other auth fields:** choose one of these patterns:
1. Omit from YAML and supply via environment variable (`DATABRICKS_HOST`, `DATABRICKS_TOKEN`, etc.). Preferred when the host is produced by an upstream system such as infrastructure-as-code output.
2. Hardcode a literal value per target under `targets.<env>.workspace:`.
3. Hardcode a literal value at the top level when there is a single environment.

Never write `workspace.host: ${var.*}`. If a task description implies dynamic host selection, the answer is always one of the three patterns above.

## Required Structure
Every `databricks.yml` this skill produces must contain the sections below, each appearing at most once. The order shown is conventional and recommended for readability:

```yaml
bundle:
  name: <literal-string>

include:
  - <glob-matching-resource-files>

variables:
  <var_name>:
    description: <text>
    # default: only when a safe env-agnostic default exists

targets:
  <target_name>:
    mode: development | production
    # default: true on at most one target
    # workspace: literal host here if not using env var
    # variables: target-specific overrides here when needed
```

`workspace:`, `resources:`, `artifacts:`, `sync:`, `permissions:`, `run_as:`, and `presets:` blocks are optional and may be added when the task requires them, subject to the singleton rule.

Things that must not appear in `databricks.yml`:
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

Every variable referenced downstream must be declared here with the same spelling. Rules:

1. One spelling per concept. Do not declare both `catalog` and `catalog_name` for the same value.
2. Provide `default:` only for values that are genuinely environment-agnostic. Do not default environment-specific values — this produces silent misconfiguration when a target forgets to override.
3. Do not declare variables that nothing downstream references. Dead variables mislead readers.
4. Do not declare a variable that exists only to carry an auth-field value (e.g. a `workspace_host` variable when the deploy model uses `DATABRICKS_HOST`). Because auth fields cannot interpolate, such a variable has no legitimate consumer.
5. Every variable needs a `description:`.

### Step 4. Define targets
Declare at least one target. The set and names depend on the repo (commonly `dev`, `test`, `prd`, but other schemes are valid).

Rules:
1. Set `default: true` on at most one target — typically the lowest-risk environment — so that `databricks bundle deploy` without `--target` is safe.
2. Use `mode: development` or `mode: production` as appropriate. These enable different CLI behaviors.
3. Put target-specific variable values under `targets.<name>.variables:` only when they are truly static per environment. When values come from an upstream system, prefer passing them via the deploy bridge so that the bundle file itself stays environment-agnostic.
4. If using hardcoded per-target hosts, place a literal URL under `targets.<name>.workspace.host:`.

### Step 5. Verify downstream consistency
Before writing, confirm that every variable name in this file matches:
1. The `--var <name>=...` flags produced by any deploy bridge.
2. Every `${var.<name>}` reference in resource files.
3. The parameter names passed to runtime entrypoints (the mapping from bundle variable to entrypoint argument is explicit in the resource files; spellings need not match, but the chain must be unambiguous).

If spellings diverge, reconcile them to a single canonical form before finishing.

### Step 6. Final validation
After writing, verify:

1. Each top-level key appears at most once.
2. `bundle.name` is a literal string with no `${...}`.
3. No `${var.*}` or `${bundle.*}` appears in `workspace.host`, `workspace.profile`, or `workspace.auth_type`.
4. `resources.jobs`, if present, is a map and not a string.
5. Every declared variable has a `description:`.
6. Every variable referenced downstream is declared.
7. Every declared variable is referenced by something (bridge, resource file, or target override).
8. `include:` entries match paths that exist in the repo.
9. No secrets or tokens are embedded.

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

1. `${...}` in `bundle.name`, `workspace.host`, `workspace.profile`, or `workspace.auth_type`.
2. `resources.jobs` set to a string file path.
3. Any top-level key appearing more than once.
4. Secrets, tokens, or credentials embedded in the file.
5. Environment-specific defaults on variables intended for use across environments.
6. Variables declared with no downstream consumer.
7. Variables whose only apparent purpose is to populate an auth field via interpolation.

## Relationship to Other Skills
- The broader `databricks-asset-bundle` skill owns resource files, runtime entrypoints, job topology, and end-to-end parameter flow. This skill defers to it for anything outside `databricks.yml`.
- Any script that generates resource files must produce output whose `${var.*}` references are declared in this file.
- Any deploy bridge must pass `--var` names that match the declarations in this file, and is the correct place to export auth-related environment variables.

## Review Checklist
- [ ] File fully replaced, not appended.
- [ ] Each top-level key appears at most once.
- [ ] `bundle.name` is a literal.
- [ ] No `${var.*}` or `${bundle.*}` in any auth field.
- [ ] No `resources.jobs: <string>`.
- [ ] Every declared variable is referenced downstream.
- [ ] Every downstream `${var.*}` reference is declared.
- [ ] Auth configuration is handled outside the file (env var or per-target literal).
- [ ] Deploy bridge `--var` names match this file's variable names.
- [ ] No secrets or tokens embedded.
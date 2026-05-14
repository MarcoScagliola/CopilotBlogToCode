---
name: databricks-asset-bundle
description: "Create, update, or review a Databricks Asset Bundle. Use when designing bundle structure, authoring jobs.yml, bundle variables, spark_python_task jobs, run_job_task orchestrators, environment targets, or mapping infrastructure outputs into bundle deployment variables. Delegates databricks.yml authoring to the databricks-yml-authoring skill, and Python entrypoint authoring to the python-entrypoints skill."
---

# Databricks Asset Bundle

## Overview
General guidance for creating and maintaining a Databricks Asset Bundle (DAB).

Use this skill when:
- coordinating bundle-wide changes (artifact-specific authoring is delegated; see Delegated Skills)
- creating or updating `resources/jobs.yml`
- defining bundle variables and deployment targets
- wiring infrastructure outputs into bundle deployment variables
- designing orchestration with `run_job_task`
- reviewing whether bundle structure, parameter flow, and job topology are coherent

This skill is intentionally generic. Adapt it to the current repository's structure and naming conventions instead of assuming a specific workload, layer model, or environment naming scheme.

## Delegated Skills
Some concerns within a bundle have their own dedicated skill and should be handled there rather than in this skill. When the work involves one of these concerns, load the named skill and follow its guidance for that artifact; return to this skill for cross-artifact coordination.

- **`databricks-yml-authoring`** — owns `databricks.yml`: bundle name, `include:` directives, variable declarations, target definitions, and workspace/auth configuration. Includes the canonical downstream-consistency check (its Step 5) that enforces variable-name parity across the bundle.
- **`python-entrypoints`** — owns individual Python entrypoint files (typically `src/<job>/main.py`): file structure, argparse contracts, secret handling, object-name construction, and the singleton rule that prevents duplicate-`main` regressions.

## Scope Boundary
The Asset Bundle owns runtime assets deployed into Databricks:
- jobs and pipelines of job tasks
- bundle variables and targets
- runtime Python entrypoints
- job notifications and schedules
- job-level parameter passing
- Unity Catalog objects that are purely runtime (catalogs, schemas, tables) when those are not provisioned as infrastructure

The Asset Bundle does not define infrastructure that belongs in Terraform or other IaC layers:
- cloud resource groups or projects
- storage accounts, buckets, or containers
- Databricks workspace creation
- Unity Catalog infrastructure objects that are provisioned as infrastructure
- secret stores themselves

Infrastructure code provisions resources; the bundle deploys runtime jobs and code into an existing workspace.

## Typical Repository Layout
```text
databricks-bundle/
  databricks.yml
  resources/
    *.yml
  src/
    <job>/main.py
```

Preserve the repo's existing folder names rather than forcing this layout.

## Bundle Contract

### databricks.yml
Treat `databricks.yml` as the declaration layer that:
- lists the bundle's runtime variables
- includes the resource files where jobs are defined
- defines the set of deployment targets

Coordination responsibilities at this skill's level:
- variables referenced by `resources/*.yml` and Python entrypoints are declared in `databricks.yml`
- environment-specific values are declared as variables rather than hardcoded in jobs or code
- target names used elsewhere exist in that file

Detailed authoring rules (structure, interpolation constraints, target `mode` placement) live in `databricks-yml-authoring`.

### Targets
Targets commonly represent environments such as `dev`, `test`, or `prd`.

- Development targets typically use `mode: development`.
- Production targets typically use `mode: production`.
- Keep target-specific host and deployment behavior inside targets rather than duplicating job definitions.

## Job Topology
`resources/jobs.yml` defines runtime jobs in a way that matches the processing model.

Typical patterns:
1. **Independent jobs** — each job runs alone.
2. **Layered jobs** — output of one job becomes input to another.
3. **Orchestrator jobs** — one job triggers downstream jobs via `run_job_task`.

Use `spark_python_task` when a task executes a Python entrypoint. Use `run_job_task` when a job orchestrates other jobs rather than duplicating their logic.

Guidance:
- Keep orchestration in `jobs.yml`, not inside Python code.
- Pass runtime values as explicit task parameters.
- Use email notifications or schedules only where operationally justified.
- Prefer simple, readable task graphs over deeply nested orchestration.

## Python Entrypoints
Treat entrypoints as leaves in the job graph:
- they receive arguments from their resource file's parameter list
- they perform a single bounded unit of work (ingest, transform, aggregate, audit)
- they never orchestrate other jobs (orchestration belongs in resource files via `run_job_task`)

Secrets never appear in `databricks.yml`, in `resources/*.yml` task parameters, or in any repository file. Secret key names stay consistent across environments. Secret-handling detail at the entrypoint level lives in `python-entrypoints`.

## Parameter Flow
Every runtime value should be traceable through this chain:
1. infrastructure output or operator-provided value
2. bundle variable
3. job task parameter
4. Python `argparse` argument
5. runtime object naming or logic

When a variable changes name anywhere in the chain, the matching change is needed in:
- bundle variable definitions in `databricks.yml`
- `jobs.yml` parameter lists
- Python entrypoint argument parsing
- the deployment bridge script
- documentation

## Infrastructure Output Mapping
Many repositories deploy the bundle using values emitted by infrastructure code: workspace host, workspace resource identifier, catalog names, schema names, service principal or identity IDs, secret scope names.

**The bundle's deployment bridge reads infrastructure outputs from a file artifact, not by invoking an IaC CLI.** The infrastructure stage writes its outputs to a machine-readable file (typically JSON). The bundle's deployment bridge reads that file and maps each value to a bundle variable. The bridge does not invoke `terraform`, `pulumi`, `bicep`, or any other IaC tool at deploy time.

Why this matters:
- The bundle deploy runner only needs the Databricks CLI and Python — not the IaC toolchain.
- The contract between infrastructure and bundle stages is a self-describing file, not an implicit shared install. If the bundle runner image changes or the IaC tool's CLI is missing, the bundle deploy keeps working.
- Bundle deploy failures stop being entangled with IaC toolchain failures (missing CLI, version drift, remote-state lookup errors).

Keep the bridge in a single layer rather than scattered across workflows and code. When the bridge gains, renames, or removes an input or output, update the bridge, the bundle variable declarations in `databricks.yml` (per `databricks-yml-authoring`), and the infrastructure outputs together so the three stay in one-to-one correspondence.

## Deployment Model
A bundle can be deployed in different ways.

### 1. Single-Workflow Deployment
One workflow or script applies infrastructure, captures its outputs, then deploys the bundle in sequence. Even in this mode, the bundle step reads outputs from the file the infrastructure step wrote — not by re-querying IaC state — so the bundle's deploy command does not depend on the IaC toolchain being available at the point of invocation.

### 2. Split Deployment
One workflow deploys infrastructure and publishes a machine-readable outputs artifact. A separate workflow downloads that artifact and deploys the bundle.

1. The infrastructure stage writes outputs to a file (e.g. `tf-outputs.json` via `terraform output -json`) and publishes it as an artifact through the CI system's artifact mechanism.
2. The bundle stage downloads the artifact and reads it as a file. It does not invoke the IaC CLI, query remote state, or otherwise depend on the infrastructure toolchain at runtime.
3. The bundle runner image installs only what the bundle deploy needs (typically the Databricks CLI and Python). A bundle deploy that fails with a missing-CLI error for an IaC tool is a signal the bridge script is reaching for live state and should be refactored to read the artifact instead.

## Bundle-Wide Principles
1. Job definitions are declarative, expressed in `jobs.yml` rather than Python.
2. Environment-specific values flow through bundle variables, not hardcoded literals.
3. Object names are catalog/schema-qualified rather than relying on implicit defaults.
4. Transform and aggregate jobs default to deterministic write behavior; append is opt-in for genuine incremental ingestion.
5. Entrypoints are leaves: focused on one unit of work, not orchestration.
6. Bundle variables, deployment bridge mappings, and documentation stay aligned.
7. The bundle deploy reads infrastructure outputs from a file artifact, not by invoking IaC CLIs.
8. The repo's existing naming conventions are preserved unless the task explicitly requires renaming.

## Required Review Checklist
Before considering bundle changes complete, verify:

1. `databricks.yml` has been reviewed against the `databricks-yml-authoring` review checklist (singleton top-level keys, literal bundle name, no `${var.*}` in auth fields, no `resources.jobs: <string>`, variable parity with downstream consumers).
2. `resources/jobs.yml` references valid relative entrypoint paths.
3. Each modified entrypoint has been reviewed against the `python-entrypoints` review checklist (singleton structure, argparse parity with its resource file, runtime-only secret handling).
4. The parameter chain is consistent end-to-end: bundle variables in `databricks.yml` → `${var.*}` references in `resources/jobs.yml` → argparse arguments in entrypoints.
5. Infrastructure output names expected by the deployment bridge still exist in the infrastructure outputs.
6. The deployment bridge reads infrastructure outputs from a file artifact and does not invoke `terraform` or other IaC CLIs. The bundle deploy runner does not need the IaC toolchain installed.
7. Workflow changes still preserve the intended infra-to-bundle handoff.
8. The bundle remains consistent across all targets.

## Common Changes
Use this skill for tasks such as:
- adjusting job names or task topology in `resources/*.yml`
- replacing Python file paths in `jobs.yml`
- adding notifications or schedules
- changing how infrastructure outputs feed bundle deployment
- converting from a single deployment workflow to split workflows
- coordinating multi-file changes where `databricks.yml`, `resources/*.yml`, and entrypoints must move together

Tasks that also modify `databricks.yml` additionally load `databricks-yml-authoring` for the `databricks.yml` portion of the work. Tasks that also modify Python entrypoints additionally load `python-entrypoints` for the entrypoint portion.
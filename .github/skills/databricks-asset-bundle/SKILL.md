---
name: databricks-asset-bundle
description: "Create, update, or review a Databricks Asset Bundle. Use when generating databricks.yml, jobs.yml, bundle variables, spark_python_task jobs, run_job_task orchestrators, environment targets, or when mapping infrastructure outputs into bundle deployment variables."
---

# Databricks Asset Bundle

## Overview
This skill captures general guidance for creating and maintaining a Databricks Asset Bundle (DAB).

Use this skill when:
- creating or updating `databricks.yml`
- creating or updating `resources/jobs.yml`
- creating or updating Python entrypoints under `src/`
- defining bundle variables and deployment targets
- wiring infrastructure outputs into bundle deployment variables
- designing orchestration with `run_job_task`
- reviewing whether bundle structure, parameter flow, and job topology are coherent

This skill is intentionally generic. Adapt it to the current repository structure and naming conventions instead of assuming a specific workload, layer model, or environment naming scheme.

## Scope Boundary
The Asset Bundle owns runtime assets deployed into Databricks, for example:
- jobs
- pipelines of job tasks
- bundle variables and targets
- runtime Python entrypoints
- job notifications and schedules
- job-level parameter passing

The Asset Bundle should not define infrastructure that belongs in Terraform or other IaC layers, for example:
- cloud resource groups or projects
- storage accounts, buckets, or containers
- Databricks workspace creation
- Unity Catalog infrastructure objects that are provisioned as infrastructure
- secret stores themselves

Keep the separation clear:
- infrastructure code provisions resources
- the bundle deploys runtime jobs and code into an existing workspace

## Typical Repository Layout
A common bundle structure looks like this:

```text
databricks-bundle/
  databricks.yml
  resources/
    jobs.yml
  src/
    <job-a>/main.py
    <job-b>/main.py
    <job-c>/main.py
```

If the current repo uses different folder names, preserve the repo's existing structure rather than forcing this layout.

## Bundle Contract

### databricks.yml
The bundle definition should usually:
- set a stable bundle name
- include `resources/*.yml` or the repo's equivalent resource pattern
- declare runtime variables explicitly
- define at least one target such as `dev`, `test`, or `prd`
- configure the workspace host through a variable or target configuration rather than hardcoding it in job definitions

Common variable categories:
- workspace connection values
- catalog/schema or database names
- service principal or identity values when jobs need them
- secret scope names
- source object names such as input table names
- operational values such as alert email or schedule

Guidance:
1. Put environment-specific values in bundle variables or target overrides.
2. Avoid hardcoding catalog, schema, workspace host, or notification recipients in Python entrypoints.
3. Keep the variable set minimal but explicit.

### Targets
Targets commonly represent environments such as:
- `dev`
- `test`
- `prd`

General guidance:
1. Development targets can use `mode: development`.
2. Production targets can use `mode: production`.
3. Keep target-specific host and deployment behavior inside targets rather than duplicating job definitions.

## Job Topology
`resources/jobs.yml` should define the runtime jobs in a way that matches the processing model.

Typical patterns:
1. Independent jobs, where each job can run alone.
2. Layered jobs, where output of one job becomes input to another.
3. Orchestrator jobs, where one job triggers downstream jobs via `run_job_task`.

Use `spark_python_task` when a task executes a Python entrypoint.
Use `run_job_task` when a job should orchestrate other jobs instead of duplicating their logic.

Guidance:
1. Keep orchestration in `jobs.yml`, not inside Python code.
2. Pass runtime values as explicit task parameters.
3. Use email notifications or schedules only where operationally justified.
4. Prefer simple, readable task graphs over deeply nested orchestration.

## Python Entrypoints
Python entrypoints under `src/` should be small runtime units with clear argument contracts.

Recommended patterns:
1. Parse arguments explicitly with `argparse`.
2. Build fully qualified object names from arguments rather than hardcoding them.
3. Read secrets at runtime through Databricks secret utilities if needed.
4. Keep transforms deterministic and idempotent when possible.

Common categories of entrypoints:
- ingestion jobs
- transformation jobs
- aggregation jobs
- orchestration checkpoint or audit jobs

### Secret Handling
If a job needs secrets:
1. Read them at runtime.
2. Do not print or log secret values.
3. Do not hardcode secrets in the bundle, repository, or task parameters.
4. Keep secret key names consistent across environments.

## Parameter Flow
One of the most important bundle design concerns is keeping parameter flow consistent across layers.

Every runtime value should be traceable through this chain:
1. infrastructure output or operator-provided value
2. bundle variable
3. job task parameter
4. Python `argparse` argument
5. runtime object naming or logic

Whenever a variable changes name, verify all affected layers:
- bundle variable definitions
- `jobs.yml` parameter lists
- Python entrypoint argument parsing
- deployment bridge scripts
- documentation

## Infrastructure Output Mapping
Many repositories deploy the bundle using values emitted by infrastructure code.

When that pattern is used:
1. Define a clear mapping from infrastructure outputs to bundle variables.
2. Keep that mapping in one bridge layer rather than scattering it across workflows and code.
3. Support reading outputs either from live infrastructure state or from an exported JSON artifact when workflow stages are split.

Typical values passed from infrastructure to bundle:
- workspace host
- workspace resource identifier
- catalog names
- schema names
- service principal or identity IDs
- secret scope names

If the repo contains a deployment bridge script, keep it aligned with both:
- the infrastructure output names
- the variable names in `databricks.yml`

## Deployment Model
A bundle can be deployed in different ways. This skill supports both common patterns:

### 1. Single-Workflow Deployment
One workflow or script:
- applies infrastructure
- reads infrastructure outputs
- deploys the bundle

### 2. Split Deployment
One workflow deploys infrastructure and exports outputs.
Another workflow downloads those outputs and deploys the bundle.

If the repo uses split workflows:
1. Infrastructure stage should publish a machine-readable outputs artifact.
2. Bundle stage should consume that artifact rather than re-running infrastructure logic.
3. Authentication for bundle deploy should be consistent with the repository's preferred model.

## Authoring Rules
When creating or changing a Databricks Asset Bundle:

1. Keep job definitions declarative in `jobs.yml`.
2. Keep environment-specific values out of Python code.
3. Prefer catalog/schema-qualified names over implicit defaults.
4. Prefer deterministic write behavior for transform and aggregate jobs.
5. Use append only when the semantics genuinely require incremental ingestion.
6. Keep Python entrypoints focused; avoid mixing orchestration with business transformation logic.
7. Keep bundle variables, deployment bridge mapping, and docs aligned.
8. Preserve the repo's existing naming conventions unless the task explicitly requires renaming.

## Required Review Checklist
Before considering bundle changes complete, verify:

1. `databricks.yml` parses and includes the intended resource files.
2. `resources/jobs.yml` references valid relative entrypoint paths.
3. All parameters passed in `jobs.yml` match the Python entrypoint arguments.
4. Secret usage is runtime-only and does not leak into logs or repository files.
5. Infrastructure output names expected by the deployment bridge still exist.
6. Workflow changes still preserve the intended infra-to-bundle handoff.
7. The bundle remains consistent across all targets.

## Common Changes
Use this skill for tasks such as:
- adding or removing bundle variables
- changing schema, catalog, or database parameter names
- adjusting job names or task topology
- replacing Python file paths in `jobs.yml`
- adding notifications or schedules
- changing how infrastructure outputs feed bundle deployment
- converting from a single deployment workflow to split workflows

Do not use this skill for:
- redesigning cloud infrastructure itself
- changing Terraform-managed resource topology without infrastructure review
- changing platform-wide secret management strategy unless that is the task
# TODO - blg dev

This file tracks deferred operator decisions and post-generation actions for the current run.

## Pre-deployment

### Confirm deployment principal RBAC
- What this is: The GitHub deployment principal must be authorized to create resources and role assignments in Azure.
- Why deferred: Access policy is tenant-specific and cannot be safely inferred from article content.
- Source: terraform skill RBAC guidance; SPEC.md Not Stated section.
- Resolution:
  1. Ensure Contributor is assigned at subscription or target resource-group scope.
  2. Ensure User Access Administrator is assigned at the same scope.
  3. Verify role propagation before dispatching infra workflow.

### Confirm Entra permissions for layer principal creation
- What this is: create mode requires directory permissions to create app registrations and service principals for bronze, silver, and gold.
- Why deferred: Tenant identity policy differs by organization.
- Source: SKILL.md identity guardrails; SPEC.md Not Stated section.
- Resolution:
  1. Confirm deployment principal can create application registrations.
  2. If blocked, switch to existing mode in a future run and pre-create principals.

## Deployment-time inputs

### Choose key_vault_recovery_mode per run
- Why deferred: Soft-delete state is runtime Azure state and not known at generation time.
- Source: SKILL.md workflow input contract.
- Resolution:
  1. Use auto for standard reruns.
  2. Use recover only when a soft-deleted vault must be recovered.
  3. Use fresh only when no recoverable vault exists.

### Choose state_strategy per run
- Why deferred: Choice depends on whether the run is destructive reset or non-destructive adoption.
- Source: SKILL.md state strategy policy.
- Resolution:
  1. Use fail for safe, non-destructive behavior.
  2. Use recreate_rg only for ephemeral dev rebuilds where deletion is acceptable.

## Post-infrastructure

### Create Databricks secret scope backed by Key Vault
- What this is: Databricks runtime bridge to the generated Key Vault.
- Why deferred: Workspace object creation occurs after infrastructure exists.
- Source: databricks-asset-bundle skill; SPEC.md security intent.
- Resolution:
  1. Create scope kv-dev-scope in workspace.
  2. Bind it to Key Vault kv-blg-dev-uks.
  3. Validate secret reads from Databricks.

### Populate runtime secrets in Key Vault
- What this is: Secret values needed by runtime ingestion and transformation logic.
- Why deferred: Secret values are operational data and must never be generated.
- Source: SKILL.md runtime secret policy; SPEC.md Not Stated section.
- Resolution:
  1. Determine required secret keys from workload implementation.
  2. Store values in Key Vault and verify access via scope.

### Finalize Unity Catalog grants and ownership
- What this is: Data-plane permissions for layer principals and downstream consumers.
- Why deferred: Consumer identities and access matrix are organization-specific.
- Source: SPEC.md Not Stated section.
- Resolution:
  1. Grant use and data privileges per layer design.
  2. Validate orchestrator run can read and write expected objects.

## Post-DAB

### Execute orchestrator functional test
- What this is: End-to-end confirmation of setup, bronze, silver, gold, and smoke-test jobs.
- Why deferred: Requires deployed workspace and runtime secrets.
- Source: SKILL.md optional functional validation.
- Resolution:
  1. Run orchestrator job.
  2. Confirm all task dependencies complete successfully.
  3. Confirm expected tables are materialized.

### Configure schedules and runbook ownership
- What this is: Operationalization of deployed jobs for ongoing use.
- Why deferred: Schedule cadence and ownership are team decisions.
- Source: SPEC.md Not Stated section.
- Resolution:
  1. Define run cadence, retry policy, and on-call ownership.
  2. Enable schedules once data-quality checks pass.

## Architectural decisions deferred

### Adopt remote Terraform backend for non-destructive repeatability
- Why deferred: Backend storage and lock design are platform choices beyond article scope.
- Source: SKILL.md state management guidance; SPEC.md Not Stated section.
- Resolution:
  1. Define backend account, container, and locking policy.
  2. Migrate state before production-style reruns.

### Define monitoring, DR, and cost governance baseline
- Why deferred: Alert thresholds, RTO/RPO, and budget controls are org-specific controls.
- Source: SPEC.md Not Stated section.
- Resolution:
  1. Add observability and alerting standards.
  2. Define DR approach and retention policy.
  3. Set cost budgets and compute guardrails.

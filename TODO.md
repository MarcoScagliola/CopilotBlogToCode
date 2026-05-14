# TODO - blg dev

This file lists unresolved values and deferred implementation actions from the generated baseline.

## Pre-deployment

### Confirm workspace SKU and network mode details from platform policy

**What this is.** The article prescribes Secure Cluster Connectivity and strong isolation, but does not pin every Azure Databricks workspace control to an exact final policy profile.

**Why deferred.** These controls are tenant policy decisions and were not fully specified in the source article.

**Source.** SPEC.md - Databricks (workspace tier not stated, network detail gaps).

**Resolution.**
1. Confirm the approved workspace SKU for this environment.
2. Confirm whether public network access must be disabled at workspace level.
3. Align Terraform variable values with those policy decisions before production deployment.

**Done looks like.** The workspace policy profile is approved and reflected in Terraform settings.

### Provide required deployment principal permissions

**What this is.** The deployment principal used by workflows must create resources and assign RBAC.

**Why deferred.** RBAC assignment cannot be self-granted by the running workflow principal.

**Source.** terraform skill and generated workflow credential contract.

**Resolution.**
1. Ensure the deployment principal has Contributor on target scope.
2. Ensure it also has User Access Administrator on target scope.
3. If layer_sp_mode=create is used, confirm directory permissions for app registration creation.

**Done looks like.** Infrastructure workflow can complete without authorization failures.

### Resolve data source system inventory and format definitions

**What this is.** The blog explains layered processing but not concrete input systems, payload formats, or ingestion contracts.

**Why deferred.** Source systems are workload-specific and were not stated in article.

**Source.** SPEC.md - Data model (source systems and formats not stated in article).

**Resolution.**
1. Document source systems and ownership.
2. Define source formats and contracts per source.
3. Update bronze logic and validation rules accordingly.

**Done looks like.** The bronze ingestion contract is documented and implemented for all sources.

## Deployment-time inputs

### Choose run-time state strategy

**Why deferred.** The right option depends on whether this run is destructive reset (`recreate_rg`) or non-destructive (`fail`).

**Source.** SKILL.md workflow input policy.

**Resolution.**
1. Use `fail` for non-destructive runs.
2. Use `recreate_rg` only for disposable environments.

### Choose key vault recovery mode

**Why deferred.** Soft-delete state is environment-dependent and cannot be inferred ahead of dispatch.

**Source.** SKILL.md workflow recovery policy.

**Resolution.**
1. Use `auto` for normal runs.
2. Use `recover` only when a known soft-deleted vault must be restored.
3. Use `fresh` only when no soft-deleted vault with the same name exists.

### Provide schedule and trigger model for orchestrator and layer jobs

**Why deferred.** Schedule cadence, trigger strategy, and concurrency were not stated in article.

**Source.** SPEC.md - Databricks (schedule/trigger/concurrency not stated in article).

**Resolution.**
1. Define business cadence for Bronze, Silver, and Gold SLAs.
2. Define orchestrator trigger policy and retries.
3. Configure job schedules and limits in workspace deployment settings.

**Done looks like.** Jobs run on approved cadence with explicit concurrency controls.

## Post-infrastructure

### Create Key Vault-backed Databricks secret scope

**What this is.** Runtime secrets are read through a Databricks secret scope mapped to Azure Key Vault.

**Why deferred.** Scope creation requires an already-deployed workspace.

**Source.** SPEC.md - Security and identity.

**Resolution.**
1. Create one scope per environment backed by the deployed Key Vault.
2. Verify workspace identity can read vault secrets.
3. Confirm scope name matches bundle variable `secret_scope`.

**Done looks like.** A notebook can read an expected secret key through the configured scope.

### Populate runtime secrets required by notebooks and jobs

**What this is.** Source credentials and integration tokens must exist in Key Vault before first workload run.

**Why deferred.** Secret values are operator-managed and must not be generated in code.

**Source.** SPEC.md - Security and identity.

**Resolution.**
1. Inventory required secret keys from workload entrypoints.
2. Populate those keys in Key Vault.
3. Validate secret read path in non-production first.

**Done looks like.** No job fails due to missing secret keys.

### Finalize Unity Catalog names and grants

**What this is.** The article requires separate catalogs/schemas per layer but does not provide concrete names or grant matrix values.

**Why deferred.** Catalog naming and grant model are tenant-specific and not stated in article.

**Source.** SPEC.md - Databricks (specific catalog/schema names not stated in article).

**Resolution.**
1. Finalize bronze/silver/gold catalog and schema names.
2. Grant least-privilege access to layer principals.
3. Validate read/write paths per layer with test runs.

**Done looks like.** Layer jobs have only required privileges and can complete end-to-end.

## Post-DAB

### Run orchestrator functional test

**What this is.** Verify setup, bronze, silver, gold, and smoke-test jobs execute in sequence and produce expected target assets.

**Why deferred.** Functional validation depends on environment readiness and source availability.

**Source.** SKILL.md functional test guidance.

**Resolution.**
1. Trigger orchestrator run.
2. Validate each dependent layer job result.
3. Verify target table existence and minimum data volumes.

**Done looks like.** All orchestration tasks complete successfully with expected outputs.

## Architectural decisions deferred

### Decide production state backend strategy

**What this is.** Local ephemeral state is acceptable for fast iteration but not for long-term production drift-safe updates.

**Why deferred.** Backend setup is a platform decision outside this generation pass.

**Source.** terraform skill state-management guidance.

**Resolution.**
1. Decide if this workload will run as long-lived environment.
2. If yes, configure remote Terraform backend and state locking.
3. Migrate workflow practices to non-destructive stateful updates.

**Done looks like.** Infrastructure reruns are stateful and do not require destructive reset.

### Define observability destination and retention controls

**What this is.** The article recommends system tables and monitoring, but exact retention and alert routing are not stated.

**Why deferred.** Monitoring destination, SLO thresholds, and retention policy were not stated in article.

**Source.** SPEC.md - Operational concerns (diagnostic destinations and thresholds not stated in article).

**Resolution.**
1. Select monitoring destinations and owners.
2. Define retention and alert thresholds per layer.
3. Implement and validate alerting against test failures.

**Done looks like.** Monitoring and alerting are operational for pipeline failures and spend anomalies.

### Define backup and disaster recovery model

**What this is.** The blog does not specify DR targets, recovery objectives, or cross-region replication choices.

**Why deferred.** DR strategy was not stated in article.

**Source.** SPEC.md - Operational concerns (backup/retention/DR strategy not stated in article).

**Resolution.**
1. Define RPO/RTO targets.
2. Select storage and metadata replication strategy.
3. Define and test restore runbook.

**Done looks like.** DR architecture and test evidence are documented and approved.

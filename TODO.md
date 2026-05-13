# TODO - blg tst

This file captures unresolved values and manual actions for the secure medallion deployment generated from the source article.

## Pre-deployment

### Confirm deployment principal RBAC baseline

**Why deferred.** Role assignments cannot be self-granted by the workflow before Terraform runs.

**Source.** terraform skill - RBAC / Permission Errors.

**Resolution.**
1. Confirm the deployment principal has Contributor and User Access Administrator on the target scope.
2. Confirm the object ID used is the Enterprise Application object ID.

### Confirm Entra permissions for layer_sp_mode=create

**Why deferred.** Tenant policy controls whether app registrations can be created by the deployment principal.

**Source.** SPEC.md Security And Identity; terraform skill - Identity Creation Restrictions.

**Resolution.**
1. Verify the deployment principal is allowed to create Entra app registrations and service principals.
2. If tenant policy blocks creation, switch to existing mode and pre-provision principals.

### Create GitHub Environment BLG2CODEDEV and populate secrets

**Why deferred.** GitHub environment configuration is outside Terraform scope.

**Source.** blog-to-databricks-iac SKILL Step 5 and Step 6.

**Resolution.**
1. Create GitHub environment BLG2CODEDEV.
2. Add AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and AZURE_SP_OBJECT_ID.

### Decide networking controls not stated in article

**Why deferred.** Part I does not define public/private endpoint policy details.

**Source.** SPEC.md Azure Services.

**Resolution.**
1. Decide whether to use private endpoints for storage, key vault, and workspace.
2. Decide whether public network access should remain enabled for initial deployment.

### Decide data source contracts not stated in article

**Why deferred.** Source systems and formats are not defined in Part I.

**Source.** SPEC.md Data Model.

**Resolution.**
1. Define concrete source systems and ingestion contracts for bronze.
2. Define expected schemas and SLAs for incoming data.

## Deployment-time inputs

### key_vault_recovery_mode for each run

**Why deferred.** The correct choice depends on current soft-delete state in the subscription.

**Source.** blog-to-databricks-iac SKILL Step 5.

**Resolution.**
1. Use auto for normal deployments.
2. Use recover or fresh only when intentionally overriding automatic behavior.

### state_strategy for each run

**Why deferred.** The correct strategy depends on whether the environment is ephemeral or persistent.

**Source.** blog-to-databricks-iac SKILL Step 5.

**Resolution.**
1. Use fail for safe, non-destructive deployments.
2. Use recreate_rg only for disposable environments.

### Validate target/environment pairing at dispatch

**Why deferred.** Workflow supports per-run target overrides.

**Source.** deploy-infrastructure workflow input contract.

**Resolution.**
1. Keep target and environment aligned with the intended promotion flow.
2. Avoid promoting with mixed values that do not match the selected GitHub environment.

### Set runtime values not stated in article

**Why deferred.** Many operational values are intentionally not specified in Part I.

**Source.** SPEC.md Architecture, Databricks, Data Model, Operational Concerns.

**Resolution.**
1. Set schedules, concurrency limits, and retry policies for each job.
2. Set concrete cluster sizing and runtime versions per layer.
3. Set table naming conventions beyond the base bronze/silver/gold model.

## Post-infrastructure

### Create AKV-backed Databricks secret scope

**Why deferred.** Secret scope creation requires an active workspace and deployed key vault.

**Source.** SPEC.md Security And Identity.

**Resolution.**
1. Create a workspace secret scope mapped to the deployed key vault.
2. Ensure the scope name matches bundle variable secret_scope.

### Populate runtime secrets in Azure Key Vault

**Why deferred.** Secret values are environment-specific and must never be in source control.

**Source.** SPEC.md Security And Identity.

**Resolution.**
1. Define required secret key names for source credentials.
2. Add each value to key vault and verify read access from workspace.

### Create or confirm Unity Catalog objects

**Why deferred.** Exact catalog/schema names and ownership policy are partially unspecified by the article.

**Source.** SPEC.md Databricks; SPEC.md Data Model.

**Resolution.**
1. Confirm bronze/silver/gold catalogs and schemas exist with intended names.
2. Assign ownership and privileges per separation-of-duties policy.

### Validate per-layer identity and storage isolation

**Why deferred.** Isolation policy is architectural; enforcement requires post-deploy verification.

**Source.** SPEC.md Security And Identity.

**Resolution.**
1. Verify each layer principal can access only its intended resources.
2. Verify cross-layer write attempts are blocked.

### Configure monitoring sinks not stated in article

**Why deferred.** Part I mentions telemetry goals but not central sink topology.

**Source.** SPEC.md Operational Concerns.

**Resolution.**
1. Decide where AKV diagnostics and workspace telemetry are retained.
2. Define alerting paths for failed jobs and abnormal cost trends.

## Post-DAB

### Run orchestrator job end-to-end

**Why deferred.** Functional validation requires infrastructure, scopes, secrets, and UC grants to be in place.

**Source.** blog-to-databricks-iac SKILL Step 9.2 functional test.

**Resolution.**
1. Execute orchestrator job and verify all layer jobs succeed in order.
2. Verify bronze/silver/gold target tables are created and populated.

### Replace scaffold transformation logic with workload logic

**Why deferred.** Part I is an architecture pattern and does not provide business-specific transformation code.

**Source.** SPEC.md Data Model.

**Resolution.**
1. Replace sample table logic in entrypoints with real source-to-target transformations.
2. Add workload-specific quality and reconciliation checks.

### Define schedules and operational runbooks

**Why deferred.** Trigger cadence and support model are not stated in the article.

**Source.** SPEC.md Architecture; SPEC.md Operational Concerns.

**Resolution.**
1. Define schedule, retry, and incident ownership per layer.
2. Publish runbooks for common operational failures.

## Architectural decisions deferred

### Remote Terraform backend strategy

**Why deferred.** This generated baseline does not provision backend state infrastructure.

**Source.** terraform skill - State Management.

**Resolution.**
1. Design and configure remote backend for persistent state and locking.
2. Migrate from ephemeral local state before production promotion.

### Storage hardening path for shared key disablement

**Why deferred.** The generated baseline keeps provider-compatible defaults for first deployment reliability.

**Source.** terraform skill - Provider Behavior Mismatches.

**Resolution.**
1. Validate all workloads authenticate with identity-based access.
2. Disable shared key access in a controlled hardening rollout.

### Network hardening scope

**Why deferred.** The article leaves endpoint and isolation topology choices open.

**Source.** SPEC.md Azure Services.

**Resolution.**
1. Define private endpoint and firewall strategy for storage, key vault, and workspace.
2. Define outbound and inbound network restrictions for Databricks compute.

### Backup and disaster recovery design

**Why deferred.** Part I does not define BCDR policy, RPO, or RTO.

**Source.** SPEC.md Operational Concerns.

**Resolution.**
1. Define data retention, backup, and restore procedures by layer.
2. Define regional failover strategy and test cadence.

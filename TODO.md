# TODO — blg dev

This file lists unresolved values and post-deployment actions for this run.

## Pre-deployment

### Deployment principal RBAC

**Why deferred.** RBAC must be granted by an operator before Terraform runs.

**Source.** terraform skill.

**Resolution.**
1. Grant `Contributor` and `User Access Administrator` at the target scope.
2. Confirm role assignments are on the Enterprise Application object ID.

**Done looks like.** Terraform create and role-assignment operations run without 403 errors.

### Entra app registration permission for `layer_sp_mode=create`

**Why deferred.** Tenant policy controls whether app registrations can be created.

**Source.** terraform skill; SPEC.md security model.

**Resolution.**
1. Ensure deployment principal can create app registrations.
2. If restricted, switch to `layer_sp_mode=existing` and pre-provision layer principals.

### GitHub environment setup

**Why deferred.** Environment secrets are repository admin configuration.

**Source.** orchestrator step 5/6.

**Resolution.**
1. Create environment `BLG2CODEDEV`.
2. Add required secrets: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SP_OBJECT_ID`.

### Resolve source systems and data formats

**Why deferred.** Source systems and formats are not specified by the article.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Define upstream sources.
2. Define ingestion format and cadence for each source.
3. Capture corresponding runtime secret keys.

### Confirm UC metastore attachment

**Why deferred.** Metastore and workspace attachment are account-level operations.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Attach the workspace to the intended metastore in `uksouth`.
2. Confirm deployment/runtime identities can manage required UC objects.

### Confirm catalog and schema naming convention

**Why deferred.** Article states separation by catalog but not concrete names.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Accept defaults (`bronze_blg_dev`, `silver_blg_dev`, `gold_blg_dev`, schema `medallion`) or update naming policy.
2. Keep Terraform locals and bundle variables aligned.

## Deployment-time inputs

### Choose `key_vault_recovery_mode`

**Why deferred.** Depends on soft-deleted Key Vault state at deployment time.

**Source.** orchestrator step 5.

**Resolution.**
1. Use `auto` by default.
2. Use `recover` only when recovery is required.
3. Use `fresh` only when no soft-deleted vault exists.

### Choose `state_strategy`

**Why deferred.** Depends on whether rerun should be destructive in ephemeral-state mode.

**Source.** orchestrator step 5.

**Resolution.**
1. Use `fail` for safe/non-destructive workflows.
2. Use `recreate_rg` only for intentional reset in dev.

### Confirm run combination for current scenario

**Why deferred.** Dispatch inputs interact (`layer_sp_mode`, recovery mode, state strategy).

**Source.** orchestrator step 5.

**Resolution.**
1. Clean first deploy: `auto/create/fail`.
2. Restricted tenant: `auto/existing/fail`.
3. Dev rebuild: `auto/(create|existing)/recreate_rg`.

### Define job triggers and schedules

**Why deferred.** Article does not specify schedule or trigger model.

**Source.** SPEC.md § Architecture; SPEC.md § Databricks.

**Resolution.**
1. Decide schedule/trigger per environment.
2. Enable schedules only after successful manual validation.

## Post-infrastructure

### Create AKV-backed Databricks secret scope

**What this is.** Databricks runtime bridge to Azure Key Vault secrets.

**Why deferred.** Requires an existing workspace and Key Vault.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Create scope `kv-dev-scope` backed by the provisioned vault.
2. Verify workspace identity can read secrets.

### Populate runtime secret keys in Key Vault

**Why deferred.** Secret values are operator-managed and not in source control.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Add keys required by entrypoints (for example `api-token`, database passwords).
2. Validate key names match runtime reads.

### Establish Unity Catalog grants per layer

**Why deferred.** Exact grants depend on real source/target table behavior.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Grant Bronze/Silver/Gold principals only required read/write privileges.
2. Keep cross-layer writes blocked by default.

### Implement setup job UC object creation details

**Why deferred.** Article does not provide concrete DDL/object list.

**Source.** SPEC.md § Databricks; SPEC.md § Data model.

**Resolution.**
1. Replace setup scaffold with UC object creation aligned to chosen naming.
2. Validate object ownership and grants after creation.

### Implement Bronze/Silver/Gold business logic

**Why deferred.** Transformations and dataset contracts are not specified by article.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Replace scaffold logic with workload-specific ingestion and transforms.
2. Add data-quality checks per layer.

## Post-DAB

### Execute orchestrator end-to-end run

**Why deferred.** Requires completed runtime wiring and secrets.

**Source.** orchestrator step 9.2 functional test.

**Resolution.**
1. Run orchestrator job.
2. Verify setup -> bronze -> silver -> gold -> smoke_test chain succeeds.

### Verify layer-isolation controls

**Why deferred.** Must be tested after real grants are in place.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Attempt disallowed cross-layer access from each layer identity.
2. Confirm operations fail with permission errors.

### Enable monitoring and alerts baseline

**Why deferred.** Alert policy thresholds are tenant/operations specific.

**Source.** SPEC.md § Operational concerns.

**Resolution.**
1. Enable Jobs monitoring views.
2. Route AKV diagnostics and define alert thresholds.

## Architectural decisions deferred

### Remote Terraform backend adoption

**Why deferred.** Baseline currently supports local/ephemeral state workflows.

**Source.** terraform skill.

**Resolution.**
1. Add remote backend for non-destructive reruns and locking.
2. Migrate state and make `state_strategy=fail` the default.

### Storage shared key hardening

**Why deferred.** Provider compatibility needs shared key during initial provisioning.

**Source.** terraform skill provider compatibility.

**Resolution.**
1. Re-apply with shared-key disabled after initial provisioning.
2. Validate all access paths still work through identity.

### Cluster policy concrete definitions

**Why deferred.** Article provides intent but not full policy constraints.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Define per-layer cluster policies (runtime, node family, policy limits).
2. Bind layer jobs to policy IDs.

### Networking posture decision

**Why deferred.** Public/private endpoint strategy is not specified by article.

**Source.** SPEC.md § Azure services.

**Resolution.**
1. Decide private endpoint/VNet posture.
2. Update Terraform accordingly.

### Secret rotation policy

**Why deferred.** Rotation cadence is environment compliance policy.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Define rotation schedule per secret class.
2. Add monitoring for expiring secrets.

### UC system tables enablement scope

**Why deferred.** Governance scope and access model depend on platform policy.

**Source.** SPEC.md § Operational concerns.

**Resolution.**
1. Enable required system schemas.
2. Grant read access to ops/finops groups.

### CI formatting gate for Terraform

**Why deferred.** Current validation focuses on semantic correctness.

**Source.** orchestrator step 9.

**Resolution.**
1. Add `terraform fmt -check` to validation workflow generator.
2. Regenerate workflow and enforce in CI.

## SPEC unresolved mapping index

- Source. SPEC.md § Architecture: source systems not stated in article.
- Source. SPEC.md § Architecture: trigger model not stated in article.
- Source. SPEC.md § Architecture: data volume not stated in article.
- Source. SPEC.md § Architecture: data frequency not stated in article.
- Source. SPEC.md § Architecture: latency targets not stated in article.
- Source. SPEC.md § Azure services: workspace tier not stated in article.
- Source. SPEC.md § Azure services: storage redundancy not stated in article.
- Source. SPEC.md § Azure services: Key Vault SKU/tier not stated in article.
- Source. SPEC.md § Azure services: networking posture not stated in article.
- Source. SPEC.md § Azure services: region/redundancy specifics not stated in article.
- Source. SPEC.md § Databricks: workspace type not stated in article.
- Source. SPEC.md § Databricks: secure cluster connectivity setting not stated in article.
- Source. SPEC.md § Databricks: catalog names not stated in article.
- Source. SPEC.md § Databricks: schema names not stated in article.
- Source. SPEC.md § Databricks: metastore reference not stated in article.
- Source. SPEC.md § Databricks: cluster policy concrete definitions not stated in article.
- Source. SPEC.md § Databricks: runtime version not stated in article.
- Source. SPEC.md § Databricks: schedule/trigger/concurrency values not stated in article.
- Source. SPEC.md § Databricks: pipeline mode triggered/continuous not stated in article.
- Source. SPEC.md § Databricks: Python/SQL/JAR/wheel source format specifics not stated in article.
- Source. SPEC.md § Databricks: library/init-script details not stated in article.
- Source. SPEC.md § Data model: source formats not stated in article.
- Source. SPEC.md § Data model: target table inventory not stated in article.
- Source. SPEC.md § Data model: partitioning strategy not stated in article.
- Source. SPEC.md § Data model: liquid clustering or z-order strategy not stated in article.
- Source. SPEC.md § Data model: schema evolution policy not stated in article.
- Source. SPEC.md § Data model: explicit quality thresholds not stated in article.
- Source. SPEC.md § Security and identity: exact Azure RBAC role list not stated in article.
- Source. SPEC.md § Security and identity: exact UC GRANT statements not stated in article.
- Source. SPEC.md § Security and identity: explicit network path matrix not stated in article.
- Source. SPEC.md § Operational concerns: concrete alert rules not stated in article.
- Source. SPEC.md § Operational concerns: concrete cost guardrails not stated in article.
- Source. SPEC.md § Operational concerns: backup strategy not stated in article.
- Source. SPEC.md § Operational concerns: retention strategy not stated in article.
- Source. SPEC.md § Operational concerns: disaster recovery strategy not stated in article.

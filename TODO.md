# TODO — blg dev

This file captures unresolved values and post-deploy actions that were not fully specified by the source article.

## Pre-deployment

### Ensure deployment principal RBAC is in place

**Why deferred.** RBAC assignment must be performed by an operator with required permissions.

**Source.** terraform skill.

**Resolution.**
1. Grant `Contributor` and `User Access Administrator` to the deployment principal at the target scope.
2. Verify role assignment uses Service Principal object IDs from Enterprise Applications.

### Ensure Entra app-registration permissions for `layer_sp_mode=create`

**Why deferred.** Tenant policy determines whether app registrations can be created at deploy time.

**Source.** terraform skill.

**Resolution.**
1. Confirm deployment principal can create app registrations.
2. If restricted, switch to `layer_sp_mode=existing` and supply existing layer principal IDs.

### Configure GitHub environment `BLG2CODEDEV`

**Why deferred.** GitHub environment creation and secret management are repository-admin operations.

**Source.** orchestrator steps 5 and 6.

**Resolution.**
1. Create environment `BLG2CODEDEV`.
2. Add required secrets: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SP_OBJECT_ID`.

### Define source systems and ingestion formats

**Why deferred.** The article does not specify concrete source systems or data formats.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Identify source systems.
2. Define ingestion format and cadence per source.
3. Define required runtime secret keys.

### Confirm Unity Catalog metastore attachment

**Why deferred.** Metastore attachment is account-level configuration.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Attach the workspace to the intended metastore in the target region.
2. Verify identities used by jobs can access required UC objects.

## Deployment-time inputs

### Select `key_vault_recovery_mode`

**Why deferred.** Soft-delete state of Key Vault can only be known at deployment time.

**Source.** orchestrator step 5.

**Resolution.**
1. Use `auto` by default.
2. Use `recover` only when recovery is known to be required.
3. Use `fresh` only when no soft-deleted vault exists.

### Select `state_strategy`

**Why deferred.** Rerun behavior depends on whether destructive reset is acceptable.

**Source.** orchestrator step 5.

**Resolution.**
1. Use `fail` for non-destructive deployments.
2. Use `recreate_rg` only for intentional dev resets.

### Define schedule and trigger model for jobs

**Why deferred.** The article does not specify schedule/trigger values.

**Source.** SPEC.md § Architecture; SPEC.md § Databricks.

**Resolution.**
1. Choose schedule or event trigger per environment.
2. Enable autonomous runs after manual verification.

## Post-infrastructure

### Create AKV-backed Databricks secret scope

**What this is.** Runtime bridge from Databricks jobs to Azure Key Vault.

**Why deferred.** Requires deployed workspace and Key Vault.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Create secret scope aligned to `secret_scope` variable.
2. Confirm workspace identity has Key Vault read permissions.

### Populate Key Vault runtime secrets

**Why deferred.** Secret values are operator-managed and must not be generated.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Add keys expected by entrypoints.
2. Verify naming alignment between code and Key Vault keys.

### Establish Unity Catalog grants by layer

**Why deferred.** Exact grants depend on actual source/target table logic.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Grant least-privilege read/write access per layer principal.
2. Keep cross-layer access denied unless explicitly required.

### Replace scaffold logic in setup and layer entrypoints

**Why deferred.** The article does not provide concrete dataset-level implementation.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Implement UC setup details in `setup/main.py`.
2. Implement Bronze/Silver/Gold transformations and checks.

## Post-DAB

### Run orchestrator end to end

**Why deferred.** Requires completed runtime wiring and secrets.

**Source.** orchestrator step 9.2.

**Resolution.**
1. Run orchestrator in Databricks.
2. Validate successful setup -> bronze -> silver -> gold -> smoke_test chain.

### Verify layer isolation controls

**Why deferred.** Must be tested after runtime grants are finalized.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Attempt disallowed cross-layer operations.
2. Confirm permission failures occur as expected.

## Architectural decisions deferred

### Adopt remote Terraform backend for non-destructive reruns

**Why deferred.** Current baseline supports ephemeral-state workflows.

**Source.** terraform skill.

**Resolution.**
1. Configure remote state backend.
2. Migrate from local state handling.

### Disable storage shared keys after initial provisioning

**Why deferred.** Provider compatibility can require shared key during first apply.

**Source.** terraform skill.

**Resolution.**
1. Reconfigure to disable shared keys after initial deploy.
2. Confirm identity-based access paths remain healthy.

### Define concrete cluster policies

**Why deferred.** Article describes policy intent, not complete policy definitions.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Define per-layer policy constraints.
2. Bind jobs to those policies.

### Decide networking posture

**Why deferred.** Article does not specify private endpoint or VNet model.

**Source.** SPEC.md § Azure services.

**Resolution.**
1. Choose public/private endpoint strategy.
2. Update Terraform resources to enforce it.

### Define secret rotation and diagnostics policy

**Why deferred.** Rotation cadence and compliance controls are environment-specific.

**Source.** SPEC.md § Security and identity; SPEC.md § Operational concerns.

**Resolution.**
1. Define rotation cadence and ownership.
2. Ensure diagnostics and alerting are configured.

### SPEC unresolved mapping index

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
- Source. SPEC.md § Databricks: cluster policy details not stated in article.
- Source. SPEC.md § Databricks: runtime version not stated in article.
- Source. SPEC.md § Databricks: schedule/trigger/concurrency not stated in article.
- Source. SPEC.md § Databricks: task source format specifics not stated in article.
- Source. SPEC.md § Databricks: libraries/init-scripts not stated in article.
- Source. SPEC.md § Data model: source formats not stated in article.
- Source. SPEC.md § Data model: target table inventory not stated in article.
- Source. SPEC.md § Data model: partitioning strategy not stated in article.
- Source. SPEC.md § Data model: liquid clustering/z-order not stated in article.
- Source. SPEC.md § Data model: schema evolution policy not stated in article.
- Source. SPEC.md § Data model: explicit quality thresholds not stated in article.
- Source. SPEC.md § Security and identity: exact RBAC role list not stated in article.
- Source. SPEC.md § Security and identity: exact UC grant statements not stated in article.
- Source. SPEC.md § Security and identity: explicit network path matrix not stated in article.
- Source. SPEC.md § Operational concerns: alert rule details not stated in article.
- Source. SPEC.md § Operational concerns: concrete cost controls not stated in article.
- Source. SPEC.md § Operational concerns: backup strategy not stated in article.
- Source. SPEC.md § Operational concerns: retention strategy not stated in article.
- Source. SPEC.md § Operational concerns: disaster recovery strategy not stated in article.

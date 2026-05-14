# TODO - blg dev

This file tracks unresolved decisions and operator actions after generation.

## Pre-deployment

### Confirm Azure RBAC for deployment principal

Why deferred. Role assignment is tenant and subscription specific and cannot be safely inferred from the article.

Source. SPEC.md security and identity section.

Resolution.
1. Ensure the deployment principal has Contributor and User Access Administrator at the target subscription scope.
2. Confirm role assignments are applied before running infrastructure deployment.

### Confirm Entra permissions for layer identity mode

Why deferred. Directory permissions vary by tenant policy and are outside repository control.

Source. SPEC.md security and identity section.

Resolution.
1. For create mode, verify the deployment principal can create app registrations and service principals.
2. If create mode is restricted, switch to existing mode and provide pre-created principal identifiers.

### Populate GitHub environment BLG2CODEDEV with required secrets

Why deferred. Secret values are operator-managed credentials.

Source. Workflow input contract and repository context.

Resolution.
1. Add AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and AZURE_SP_OBJECT_ID in BLG2CODEDEV.
2. If existing mode is used later, add EXISTING_LAYER_SP_CLIENT_ID and EXISTING_LAYER_SP_OBJECT_ID.

## Deployment-time inputs

### key_vault_recovery_mode selection per run

Why deferred. Soft-delete state exists only at runtime in the target subscription.

Source. Deploy workflow contract.

Resolution.
1. Use auto for normal runs.
2. Use recover only when known soft-deleted vault recovery is required.
3. Use fresh only when no recoverable vault exists.

### state_strategy selection per run

Why deferred. State handling depends on whether deployment is ephemeral or persistent.

Source. Deploy workflow contract.

Resolution.
1. Use fail for non-destructive runs.
2. Use recreate_rg only for disposable environments where full recreation is acceptable.

### Fill architecture values not stated in article

Why deferred. The article intentionally leaves implementation specifics open.

Source. SPEC.md entries marked not stated in article.

Resolution.
1. Choose concrete catalog and schema names for each layer.
2. Choose concrete source systems, dataset names, and schedules.
3. Choose concrete workspace tier and runtime policy values.

## Post-infrastructure

### Create AKV-backed Databricks secret scope

Why deferred. Secret scopes require an existing workspace and Key Vault deployment.

Source. SPEC.md secrets and credentials section.

Resolution.
1. Create one secret scope in the workspace backed by the deployed Key Vault.
2. Use the same scope name configured in bundle variable secret_scope.

### Populate runtime secrets in Key Vault

Why deferred. Runtime credentials must not be generated or stored in repository artifacts.

Source. SPEC.md secrets and credentials section.

Resolution.
1. Add the required secret keys used by notebook and Python entrypoints.
2. Validate non-production secret access before production rollout.

### Establish Unity Catalog objects and grants

Why deferred. Object names and privilege models are tenant-specific governance decisions.

Source. SPEC.md Unity Catalog and security sections.

Resolution.
1. Create or confirm Bronze, Silver, and Gold catalogs and schemas.
2. Grant least-privilege rights to each layer principal for only required sources and targets.

## Post-DAB

### Run orchestrator functional smoke test

Why deferred. End-to-end execution requires infrastructure, secrets, and grants to be in place first.

Source. SKILL.md functional validation guidance.

Resolution.
1. Trigger the orchestrator job after DAB deployment.
2. Verify setup, bronze, silver, gold, and smoke-test tasks all complete.

## Architectural decisions deferred

### Remote Terraform state backend

Why deferred. This baseline favors first-run reproducibility and does not configure backend infrastructure.

Source. Terraform skill state-management guidance.

Resolution.
1. Decide whether this environment needs persistent non-destructive updates.
2. If yes, introduce remote backend storage and lock strategy, then migrate state.

### Storage shared key hardening

Why deferred. Some provider operations remain safer with shared key enabled at initial provisioning.

Source. Terraform skill provider-compatibility guidance.

Resolution.
1. Keep shared key enabled for baseline deployment compatibility.
2. Disable it in a controlled hardening pass after validating all identity-based access paths.

### Observability and cost-governance depth

Why deferred. The article provides principles but not environment-specific dashboards, alerts, and thresholds.

Source. SPEC.md operational concerns.

Resolution.
1. Enable and grant access to Databricks system tables.
2. Define layer-level alerts, retries, and budget controls aligned to operational SLOs.
# TODO - blg dev

This file tracks unresolved decisions and post-deployment actions for the generated secure medallion stack.

## Pre-deployment

### Confirm deployment principal RBAC at subscription scope

**Why deferred.** Role grants must be applied by the tenant/subscription operator before workflow execution.

**Source.** Terraform permission model and deployment workflow requirements.

**Resolution.**
1. Ensure the deployment principal behind AZURE_CLIENT_ID has Contributor on the target scope.
2. Ensure the same principal has User Access Administrator on the same scope for role assignment operations.
3. Verify both grants before the first infrastructure workflow run.

### Confirm Microsoft Entra permissions for layer_sp_mode=create

**Why deferred.** Directory-level app and service principal creation rights are tenant-governed and cannot be auto-granted.

**Source.** Terraform identity creation path for create mode.

**Resolution.**
1. Verify the deployment principal can create app registrations/service principals in Entra ID.
2. If restricted, switch to layer_sp_mode=existing and provide existing principal IDs/secrets.

### Create and populate GitHub Environment BLG2CODEDEV

**Why deferred.** Environment secrets are GitHub platform configuration and must be set by repository operators.

**Source.** Workflow secret contract.

**Resolution.**
1. Create the GitHub environment named BLG2CODEDEV.
2. Add AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SP_OBJECT_ID.
3. Optionally add EXISTING_LAYER_SP_CLIENT_ID and EXISTING_LAYER_SP_OBJECT_ID if existing mode is used.

## Deployment-time inputs

### Choose key_vault_recovery_mode per run

**Why deferred.** The correct behavior depends on whether a soft-deleted vault already exists for the target name.

**Source.** Deployment workflow recovery state machine.

**Resolution.**
1. Use auto for normal runs.
2. Use recover only when recovery is known to be needed.
3. Use fresh only when no soft-deleted vault exists for the target name.

### Choose state_strategy per run

**Why deferred.** Rerun behavior differs between clean rebuild and non-destructive adoption scenarios.

**Source.** Deployment workflow state strategy.

**Resolution.**
1. Use fail for safer runs where existing resources must be preserved.
2. Use recreate_rg only for destructive dev rebuilds.

### Provide runtime values not explicitly defined by the article

**Why deferred.** These values are environment-specific and intentionally not guessed.

**Source.** SPEC.md sections with unstated operational details.

**Resolution.**
1. Select the exact source system connectors and file/message formats for Bronze ingestion.
2. Decide schedule frequency and SLA targets for Bronze/Silver/Gold jobs.
3. Define network hardening posture for storage, Key Vault, and workspace access paths.

## Post-infrastructure

### Create AKV-backed Databricks secret scope

**Why deferred.** Secret scope creation happens inside the workspace after infra exists.

**Source.** Databricks secret handling pattern in SPEC.md.

**Resolution.**
1. Create a workspace secret scope bound to the deployed Key Vault.
2. Ensure the scope name matches the deployed secret_scope value.
3. Validate secret retrieval from a workspace notebook.

### Populate runtime secrets in Key Vault

**Why deferred.** Secret values are operator-owned credentials and are not stored in repository artifacts.

**Source.** SPEC.md security and identity guidance.

**Resolution.**
1. Identify all keys referenced by layer entrypoints.
2. Populate those keys with production-safe values in Key Vault.
3. Verify least-privilege read access for layer principals.

### Finalize Unity Catalog grants and object ownership

**Why deferred.** Fine-grained permissions depend on organizational governance policy and consumer groups.

**Source.** SPEC.md Unity Catalog least-privilege model.

**Resolution.**
1. Grant per-layer principals only required privileges on layer catalogs/schemas.
2. Verify access connectors have correct storage permissions.
3. Assign durable ownership to approved admin groups/principals.

## Post-DAB

### Run orchestrator and smoke test jobs end-to-end

**Why deferred.** Functional validation requires deployed infra, secret scope, and runtime secret population.

**Source.** Medallion orchestration design in SPEC.md.

**Resolution.**
1. Execute orchestrator job for dev target.
2. Confirm each dependent job succeeds in order.
3. Validate Bronze, Silver, and Gold tables are created and populated.

## Architectural decisions deferred

### Adopt remote Terraform state for non-destructive reruns

**Why deferred.** Initial scaffold favors rapid bootstrap over backend-state setup complexity.

**Source.** Workflow state strategy and Terraform operating model.

**Resolution.**
1. Provision a remote backend for Terraform state and locking.
2. Configure backend settings for infra/terraform.
3. Migrate local state and standardize on state_strategy=fail for stable environments.

### Tighten network controls beyond baseline

**Why deferred.** The article emphasizes secure architecture but does not prescribe exact private-link and firewall topology.

**Source.** SPEC.md networking posture.

**Resolution.**
1. Decide private endpoint strategy for Storage, Key Vault, and Databricks.
2. Apply policy-compliant firewall and routing controls.
3. Validate connectivity from workspace compute to required data/control planes.
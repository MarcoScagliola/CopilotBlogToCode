# TODO — blg dev

This file lists unresolved operator actions and decisions after generation.

## Pre-deployment

### Deployment principal has required Azure roles

**What this is.** The deployment service principal used by GitHub Actions must be able to create resources and assign roles.

**Why deferred.** Role assignment is an operator-controlled subscription action.

**Source.** `terraform` skill and deploy workflow requirements.

**Resolution.**
1. Grant Contributor at deployment scope.
2. Grant User Access Administrator at deployment scope.
3. Verify role assignments before running infrastructure deployment.

### GitHub environment BLG2CODEDEV has all required secrets

**What this is.** Workflows read ARM credentials and object IDs from GitHub Environment secrets/variables.

**Why deferred.** Secret values are external credentials and cannot be generated into repository files.

**Source.** Deploy workflow generators.

**Resolution.**
1. Ensure BLG2CODEDEV exists.
2. Set AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SP_OBJECT_ID.
3. If using existing layer principals, set EXISTING_LAYER_SP_CLIENT_ID and EXISTING_LAYER_SP_OBJECT_ID.

### Networking hardening depth (private endpoints/firewall model)

**Why deferred.** Private-endpoint and firewall posture is not stated in article.

**Source.** SPEC.md section Azure services.

**Resolution.**
1. Decide whether storage, key vault, and workspace require private endpoints.
2. Decide if public network access must be disabled on all data-plane resources.
3. Update Terraform to enforce the chosen model.

## Deployment-time inputs

### Choose key_vault_recovery_mode for each run

**Why deferred.** Depends on soft-deleted vault state at deployment time.

**Source.** Deploy workflow input contract.

**Resolution.**
1. Use auto for standard runs.
2. Use recover only when a matching soft-deleted vault must be restored.
3. Use fresh only when no conflicting deleted vault exists.

### Choose state_strategy for each run

**Why deferred.** Depends on whether the run is destructive-rebuild or non-destructive reuse.

**Source.** Deploy workflow input contract.

**Resolution.**
1. Use fail for safe/non-destructive runs.
2. Use recreate_rg only for disposable environments.

### Decide target region/redundancy profile

**Why deferred.** Region and replication requirements are not stated in article.

**Source.** SPEC.md section Azure services.

**Resolution.**
1. Confirm the production region(s).
2. Decide storage redundancy strategy per layer.
3. Align Terraform variables and policies with this decision.

### Decide workspace tier and runtime baseline

**Why deferred.** Workspace tier and exact Databricks runtime version are not stated in article.

**Source.** SPEC.md section Databricks.

**Resolution.**
1. Choose workspace tier by governance/features required.
2. Choose supported DBR family/version and cluster policy constraints.
3. Update bundle and policy definitions accordingly.

## Post-infrastructure

### Create Key Vault-backed Databricks secret scope

**What this is.** Databricks runtime secret access bridge to Azure Key Vault.

**Why deferred.** Requires workspace-side object creation after infrastructure exists.

**Source.** SPEC.md section Security and identity.

**Resolution.**
1. Create a secret scope for the environment.
2. Bind it to the deployed Key Vault.
3. Validate a secret read path.

### Populate runtime secret keys

**Why deferred.** Secret values are environment-specific and not provided by the article.

**Source.** SPEC.md sections Data model and Security and identity.

**Resolution.**
1. Enumerate required secret keys used by entrypoints.
2. Insert corresponding secret values in Key Vault.
3. Confirm key naming consistency between jobs and vault entries.

### Decide source interfaces and schema governance

**Why deferred.** Exact source systems/formats and schema-evolution policy are not stated in article.

**Source.** SPEC.md section Data model.

**Resolution.**
1. Define each source endpoint and format contract.
2. Define schema evolution/enforcement policy per layer.
3. Update Bronze/Silver logic to enforce that policy.

## Post-DAB

### Validate orchestrator job end-to-end

**What this is.** Functional run of setup -> bronze -> silver -> gold -> smoke test.

**Why deferred.** Requires deployed infrastructure, populated secrets, and approved data access.

**Source.** SKILL validation step (functional test).

**Resolution.**
1. Trigger orchestrator job in workspace.
2. Verify each layer run succeeds.
3. Verify expected target tables are created/updated with data.

## Architectural decisions deferred

### Move from ephemeral local Terraform state to remote backend

**Why deferred.** Baseline generation targets first-run simplicity; production runs require persistent state.

**Source.** SKILL state management policy.

**Resolution.**
1. Create a remote backend storage location for state.
2. Configure backend settings and migrate state.
3. Use non-destructive reruns with state_strategy=fail.

### Define DR/retention controls

**Why deferred.** Backup, retention, and DR strategy are not stated in article.

**Source.** SPEC.md section Operational concerns.

**Resolution.**
1. Define RPO/RTO targets.
2. Add backup/retention policies aligned to those targets.
3. Validate restoration runbooks.

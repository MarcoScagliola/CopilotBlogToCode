# TODO — blg dev

This file lists everything not yet resolved by the generated artifacts. Items are grouped by when they need to be addressed. Each entry explains what the action is, why the orchestrator did not do it, and what done looks like at the level of concepts, not commands.

The five sections below are always present. Per-workload entries are added by the orchestrator based on `SPEC.md`.

## Pre-deployment

### Deployment principal has the required Azure RBAC roles

**What this is.** The deployment principal is the Azure service principal whose credentials are stored in the GitHub Environment as `AZURE_CLIENT_ID` and `AZURE_CLIENT_SECRET`. It is the identity Terraform uses to provision every resource in `infra/terraform/`.

The required roles are not narrow. Terraform creates a resource group, storage accounts, a Key Vault, a Databricks workspace, access connectors, and several role assignments. The deployment principal therefore needs broad resource-creation permission and the ability to assign roles to other identities.

**Why deferred.** RBAC assignment must happen before the first Terraform apply. The deployment workflow uses the deployment principal's credentials to run; it cannot grant itself permissions it does not yet have.

**Source.** `terraform` skill - RBAC / Permission Errors.

**Resolution.**
1. Identify the deployment principal in Azure by matching the Application (client) ID from the GitHub secret `AZURE_CLIENT_ID` to the corresponding Enterprise Application.
2. At subscription scope, assign at minimum the `Contributor` role and the `User Access Administrator` role.
3. Verify the assignments are in place before triggering the deployment workflow.

**Done looks like.** A role list query against the deployment principal at subscription scope returns at least `Contributor` and `User Access Administrator`.

### Deployment principal has Entra ID permissions if the layer principals are created from Terraform

**What this is.** The generated Terraform currently creates bronze, silver, and gold service principals directly. Creating those identities is a directory-level operation in Entra ID, not a subscription-level one.

**Why deferred.** Tenant policy may restrict service principal creation in ways the orchestrator cannot detect in advance.

**Source.** `terraform` skill - Identity Creation Restrictions.

**Resolution.**
1. If the tenant allows it, grant the deployment principal the directory permissions needed to create app registrations and service principals.
2. If the tenant blocks it, regenerate the infrastructure in an existing-principal mode and supply the layer principal identifiers explicitly.

**Done looks like.** Terraform can create the layer identities without `Authorization_RequestDenied` errors, or the deployment is regenerated to reuse pre-created identities.

### GitHub Environment `BLG2CODEDEV` exists with all required secrets

**What this is.** The GitHub Environment is the scoped container that holds the Azure credentials used by the workflows.

**Why deferred.** GitHub Environment configuration is outside Terraform's reach.

**Source.** SKILL.md Step 6; deploy bridge variable contract.

**Resolution.**
1. Create or verify the GitHub Environment named `BLG2CODEDEV`.
2. Populate `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, and `AZURE_SP_OBJECT_ID`.
3. Keep the values as GitHub secrets, not repository variables.

**Done looks like.** The environment exists and the deploy workflows can read the Azure credentials without missing-secret errors.

## Deployment-time inputs

### `key_vault_recovery_mode` - choose per-run when dispatching the workflow

**Why deferred.** The right value depends on whether a Key Vault with the target name exists in a soft-deleted state from a prior deploy.

**Source.** SKILL.md Step 5 workflow inputs; `terraform` skill - Key Vault Soft-Delete Recovery.

**Resolution.**
- Use `auto` for normal runs.
- Use `recover` when you know a soft-deleted vault exists and want the workflow to recover it.
- Use `fresh` only when you are certain no soft-deleted vault exists with the target name.

### `state_strategy` - choose per-run when dispatching the workflow

**Why deferred.** The baseline keeps Terraform state local to the runner. On rerun, Terraform has no state and treats existing Azure resources as unmanaged.

**Source.** SKILL.md Step 5 state-strategy policy.

**Resolution.**
- Use `fail` for runs where existing resources must be preserved.
- Use `recreate_rg` only for ephemeral runs where full resource-group deletion is acceptable.

### Define the combination of run-time controls for this baseline

**Why deferred.** The article does not specify whether this deployment is a lab-style resettable environment or a persistent environment with remote state.

**Source.** SPEC.md § Operational concerns; SPEC.md § Architectural decisions deferred.

**Resolution.**
1. Decide whether the deployment should remain ephemeral or be converted to remote state.
2. Confirm the intended dispatch values for `key_vault_recovery_mode` and `state_strategy` before each run.

**Done looks like.** The workflow inputs match the intended deployment lifecycle and do not surprise the operator with destructive reruns.

## Post-infrastructure

### Create the Azure Key Vault-backed Databricks secret scope

**What this is.** A Databricks secret scope is the named bridge through which jobs read Azure Key Vault secrets at runtime.

**Why deferred.** A secret scope requires a workspace to already exist and be reachable.

**Source.** `databricks-asset-bundle` skill - Scope Boundary; SPEC.md § Security and identity.

**Resolution.**
1. Identify the Key Vault Terraform provisioned and the workspace that will read it.
2. Create the Key Vault-backed secret scope using the generated scope name `kv-dev-scope`.
3. Verify the workspace identity can read from the vault.

**Done looks like.** The scope exists, points at the generated Key Vault, and secret reads succeed from the workspace.

### Populate Azure Key Vault with the runtime secrets the bundle reads

**What this is.** Runtime secrets are the source-system credentials or API keys the jobs read from the secret scope at execution time.

**Why deferred.** The article does not name the concrete secrets, so the orchestrator cannot invent them.

**Source.** SPEC.md § Security and identity; SPEC.md § Other observations.

**Resolution.**
1. Decide which source systems the workload will actually ingest from.
2. Define the secret key names and store the values in the generated Key Vault.
3. Keep the key names stable across environments.

**Done looks like.** Every runtime secret the jobs need exists in the Key Vault and can be resolved from the secret scope.

### Replace the synthetic medallion tables with the real business tables

**What this is.** The generated bundle uses synthetic managed tables so the jobs can run end-to-end even though the article does not name source datasets or target table contracts.

**Why deferred.** The article never specifies the real upstream datasets, the exact target table names, or the transformation rules between layers.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Define the real Bronze input, Silver transformation, and Gold consumption tables.
2. Replace the scaffolded table names with the business names that belong to the workload.
3. Preserve the catalog and schema boundaries already generated.

**Done looks like.** The bronze, silver, and gold jobs read and write the production table set instead of the synthetic scaffold.

### Confirm the Unity Catalog privilege model for human consumers

**What this is.** The generated baseline establishes the runtime principals, but the article does not define how human users or downstream groups should be granted catalog access.

**Why deferred.** Consumer access is a tenant and operating-model decision, not a blog-derived constant.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Decide which groups own the catalogs and which groups merely consume them.
2. Grant the human or group principals the catalog and schema rights that match the operating model.
3. Verify the generated tables are visible only where intended.

**Done looks like.** The catalogs and schemas are accessible to the right groups and blocked from the wrong ones.

## Post-DAB

### Verify the orchestrator job runs end-to-end

**What this is.** The bundle deploys the jobs, but the first real signal that the whole chain works is a successful orchestrator run.

**Why deferred.** Functional validation requires the deployed pipeline to actually execute.

**Source.** SKILL.md Step 10.2.8 functional test.

**Resolution.**
1. Trigger the orchestrator job in the deployed workspace.
2. Confirm Bronze, Silver, and Gold each run once and complete.
3. Confirm the smoke test passes after the layered jobs finish.

**Done looks like.** The orchestrator run completes without permission, secret, or storage errors.

### Review the output tables for the generated scaffold

**What this is.** The synthetic bronze, silver, and gold tables are the generated proof that the medallion chain is wired correctly.

**Why deferred.** They only exist after the bundle has been deployed and run.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Inspect the bronze, silver, and gold managed tables in Unity Catalog.
2. Confirm each table has at least one row after the smoke test.
3. Replace the scaffolded names once the real workload tables are decided.

**Done looks like.** The tables exist, are populated, and reflect the intended layer flow.

## Architectural decisions deferred

### Confirm the Databricks workspace tier and cluster connectivity posture

**What this is.** The article uses Unity Catalog, but it does not state the workspace tier or whether secure cluster connectivity is required.

**Why deferred.** These are platform decisions that depend on cost, governance, and network posture.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Decide whether the workspace should remain on the inferred Premium tier or be tightened further.
2. Decide whether secure cluster connectivity and private networking are required.
3. Regenerate the infrastructure if the network model changes.

**Done looks like.** The workspace tier and connectivity settings match the platform policy instead of the article's silence.

### Decide on network restrictions and private endpoints

**What this is.** The article does not state whether storage, Key Vault, or the workspace should be public or private.

**Why deferred.** Network hardening often requires additional infrastructure and is environment-specific.

**Source.** SPEC.md § Azure services; SPEC.md § Security and identity.

**Resolution.**
1. Decide whether the deployment should keep public endpoints or move to private endpoints.
2. Add the supporting network infrastructure before tightening access.
3. Revisit the generated Azure resource settings after the network model is chosen.

**Done looks like.** The deployed Azure resources reflect the chosen network boundary model.

### Choose the runtime libraries, notebook runtime, and init-script policy

**What this is.** The article does not specify the Databricks runtime version or any non-standard libraries.

**Why deferred.** Runtime compatibility depends on the actual workload, not just the architecture pattern.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Choose the Databricks runtime and any required Python packages.
2. Decide whether init scripts are necessary.
3. Update the bundle if the workload requires non-default dependencies.

**Done looks like.** The runtime stack is documented and repeatable instead of relying on implicit defaults.

### Define backup, retention, and disaster recovery expectations

**What this is.** The article does not define backup windows, retention periods, or recovery objectives.

**Why deferred.** DR policy is an operational decision that depends on business requirements.

**Source.** SPEC.md § Operational concerns.

**Resolution.**
1. Decide the retention and recovery objectives for the storage accounts and Key Vault.
2. Decide whether additional backup tooling is required.
3. Document the chosen policy alongside the deployment process.

**Done looks like.** The team can explain how the medallion data and secrets are recovered after a failure.

### Define monitoring, logging, and cost controls beyond the built-in system tables

**What this is.** The article mentions system tables and the Jobs UI, but it does not define alerting destinations or cost guardrails.

**Why deferred.** Those choices depend on the operator's observability stack and budget policy.

**Source.** SPEC.md § Operational concerns.

**Resolution.**
1. Decide whether to route logs to a monitoring workspace or another observability system.
2. Decide whether job alerts, budgets, or usage thresholds are required.
3. Add the chosen controls after the baseline deployment is working.

**Done looks like.** The environment has a deliberate monitoring and cost posture rather than implicit defaults.

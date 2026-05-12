# TODO — blg dev

This file lists everything not yet resolved by the generated artifacts. Items are grouped by when they need to be addressed. Each entry explains what the action is, why the orchestrator did not do it, and what done looks like.

## Pre-deployment

### Deployment principal has the required Azure RBAC roles

What this is: The deployment principal is the service principal from `AZURE_CLIENT_ID` and `AZURE_CLIENT_SECRET` used by Terraform in CI.

Why deferred: RBAC assignment must exist before workflow execution; the workflow cannot grant itself missing rights.

Source: terraform skill — RBAC / Permission Errors.

Resolution:
1. Assign `Contributor` at subscription scope.
2. Assign `User Access Administrator` at subscription scope.
3. Verify role assignments before first deploy.

Done looks like: Infrastructure workflow creates resources and role assignments without 403 errors.

### Deployment principal has Entra ID permissions for layer principal creation (`layer_sp_mode=create`)

What this is: In create mode, Terraform creates three Entra app registrations and three service principals (bronze, silver, gold).

Why deferred: App registration permissions are tenant policy decisions outside repository control.

Source: terraform skill — Identity Creation Restrictions.

Resolution:
1. Grant directory permission allowing app registration/service principal creation (for example `Application.ReadWrite.All`) to the deployment principal.
2. If tenant policy blocks this, switch to `layer_sp_mode=existing` and provide existing-layer identifiers.

Done looks like: Apply completes without `Authorization_RequestDenied` from Microsoft Graph.

### GitHub Environment BLG2CODEDEV exists with required secrets

What this is: Workflows resolve ARM credentials from GitHub Environment secrets/variables.

Why deferred: GitHub environment setup is external platform configuration.

Source: blog-to-databricks-iac skill Step 5/6 and REPO_CONTEXT contract.

Resolution:
1. Create GitHub Environment `BLG2CODEDEV`.
2. Add `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SP_OBJECT_ID`.
3. If using existing mode, add `EXISTING_LAYER_SP_CLIENT_ID` and `EXISTING_LAYER_SP_OBJECT_ID`.
4. Confirm object IDs are from Enterprise Applications.

Done looks like: Workflows start without missing-secret errors.

## Deployment-time inputs

### key_vault_recovery_mode

Why deferred: Soft-delete state of target vault is runtime state, not known at generation time.

Source: blog-to-databricks-iac skill Step 5 soft-delete recovery state machine.

Resolution:
1. Use `auto` for normal runs.
2. Use `recover` when you know a soft-deleted vault exists and needs recovery.
3. Use `fresh` only when no soft-deleted vault with that name exists.

### state_strategy

Why deferred: Choice depends on whether this run is destructive dev reset or state-preserving deployment.

Source: blog-to-databricks-iac skill Step 5 state strategy.

Resolution:
1. Use `fail` for safe/state-preserving behavior.
2. Use `recreate_rg` only for destructive clean-slate dev reruns.

Done looks like: Workflow behavior matches intended rerun strategy.

### Source systems and ingestion formats are not stated in article

Why deferred: SPEC.md marks source systems/formats as not stated in article.

Source: SPEC.md Data model.

Resolution:
1. Define the source systems (databases, APIs, files, streams).
2. Define source formats (CSV, JSON, Parquet, etc.).
3. Update Bronze entrypoint logic to reflect these decisions.

### Job schedules are not stated in article

Why deferred: Article explains architecture but not schedule cadence.

Source: SPEC.md Architecture / Databricks.

Resolution:
1. Define schedule per job (bronze/silver/gold/orchestrator).
2. Configure schedules in Databricks jobs after deployment.
3. Define retry and alert strategy.

## Post-infrastructure

### Create AKV-backed Databricks secret scope

What this is: Scope bridging Databricks secret APIs to Azure Key Vault.

Why deferred: Requires deployed workspace and Key Vault.

Source: databricks-asset-bundle skill scope boundary.

Resolution:
1. Create scope `kv-dev-scope` in workspace.
2. Link it to Key Vault `kv-blg-dev-uks`.
3. Validate scope visibility from workspace runtime.

Done looks like: Secret scope exists and can resolve secrets from Key Vault.

### Populate runtime secrets in Key Vault

What this is: Secret values consumed by entrypoints at runtime.

Why deferred: Credentials are operator-owned and must not be generated or committed.

Source: blog-to-databricks-iac skill Step 6 runtime secrets.

Resolution:
1. Identify required secret keys from entrypoint implementations.
2. Create corresponding secrets in Key Vault.
3. Validate read access from Databricks runtime.

Done looks like: Jobs read secrets without not-found or permission failures.

### Establish Unity Catalog object model and grants

What this is: Catalog/schema/table ownership and least-privilege grants for layer principals.

Why deferred: Workload-specific grants depend on unresolved table model and consumers.

Source: SPEC.md Databricks and Security sections.

Resolution:
1. Create or confirm bronze/silver/gold catalogs and schemas.
2. Grant layer principals only required privileges for their layer.
3. Validate access connector RBAC to corresponding storage accounts.

Done looks like: Layer jobs run without Unity Catalog privilege errors.

### Implement Bronze/Silver/Gold production logic

What this is: Replace scaffolded Python entrypoints with actual ingestion/transform/aggregation code.

Why deferred: Article does not provide source-specific implementation details.

Source: SPEC.md Data model (not stated in article items).

Resolution:
1. Implement Bronze ingestion into managed tables.
2. Implement Silver transformations consuming Bronze outputs.
3. Implement Gold serving logic consuming Silver outputs.
4. Add schema validation and quality checks.

## Post-DAB

### Run orchestrator end-to-end and verify outputs

What this is: Functional validation that all layer jobs execute in sequence and produce expected datasets.

Why deferred: Requires deployed infra, configured secrets, grants, and completed entrypoint logic.

Source: blog-to-databricks-iac skill Step 9.2 functional test.

Resolution:
1. Trigger orchestrator job.
2. Verify bronze → silver → gold execution succeeds.
3. Validate output tables and row counts against expectations.

Done looks like: End-to-end run succeeds with no auth/secret/RBAC/schema failures.

## Architectural decisions deferred

### Local-only Terraform state

What this is: Current workflow uses ephemeral local state in CI.

Why deferred: Baseline optimized for fast iteration rather than durable collaborative state.

Source: terraform skill State Management.

Resolution:
1. Decide if environment is moving toward production.
2. Configure remote backend for state persistence and locking.
3. Migrate state and standardize on non-destructive reruns.

Done looks like: Terraform state persists across runs with lock-protected updates.

### Keep or harden `shared_access_key_enabled`

What this is: Storage accounts are created with `shared_access_key_enabled=true` for provider compatibility.

Why deferred: Hardening can break provisioning if done before initial stable apply.

Source: terraform skill Provider Behavior Mismatches.

Resolution:
1. Confirm all access paths use identity-based auth.
2. Disable shared key access in a controlled follow-up hardening pass.
3. Re-validate workloads.

Done looks like: Storage accounts run with shared-key access disabled and workloads still function.

### Add terraform formatting gate

What this is: CI currently validates syntax/planability but not formatting drift.

Why deferred: Non-blocking hygiene improvement.

Source: blog-to-databricks-iac skill Step 9.2 verification commands.

Resolution:
1. Add terraform formatting check to validation workflow generator.
2. Regenerate workflow and enforce in CI.

Done looks like: PRs fail when Terraform formatting diverges.

### Cluster policy definitions are not stated in article

Why deferred: Article discusses policy intent but provides no concrete policy JSON/rules.

Source: SPEC.md Databricks (cluster policies not stated in article).

Resolution:
1. Define per-layer cluster policy constraints (node family, autoscale limits, runtime constraints).
2. Apply policies to bundle jobs.
3. Validate policy compliance in workspace.

### Monitoring and retention details are not stated in article

Why deferred: Article references observability goals but does not specify concrete retention/alert thresholds.

Source: SPEC.md Operational concerns.

Resolution:
1. Define system table enablement and retention goals.
2. Define alerting thresholds for job failures/cost/runtime.
3. Implement monitoring runbook for on-call use.

# TODO - blg dev

This file tracks unresolved operator actions and deployment-time decisions for this generation.

## Pre-deployment

### Configure GitHub Environment BLG2CODEDEV

What this is: The workflows read Azure credentials and identity identifiers from the GitHub environment BLG2CODEDEV.

Why deferred: Repository generation cannot create or populate your repository environment secrets.

Source: SKILL.md Step 4/5/7 workflow inputs and credential policy.

Resolution:
1. Create or confirm the BLG2CODEDEV GitHub environment.
2. Add secrets AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SP_OBJECT_ID.
3. If using existing layer principals, also add EXISTING_LAYER_SP_CLIENT_ID and EXISTING_LAYER_SP_OBJECT_ID.

Done looks like: Workflow secret validation step succeeds with no missing-value errors.

### Assign required deployment principal roles

What this is: Terraform provisioning and role assignment operations need sufficient Azure RBAC on target scope.

Why deferred: Role assignment requires tenant/subscription administrative action.

Source: terraform skill RBAC and permission guidance.

Resolution:
1. Assign Contributor and User Access Administrator to deployment principal AZURE_CLIENT_ID at required scope.
2. Confirm the object ID used for AZURE_SP_OBJECT_ID is from Enterprise Applications.

Done looks like: Deploy infrastructure workflow proceeds without authorization failures.

### Determine region and redundancy policy

Why deferred: SPEC.md records that explicit redundancy policy and region constraints were not stated in article.

Source: SPEC.md section Azure Services (region and redundancy not stated in article).

Resolution:
1. Confirm uksouth remains the approved region for this workload.
2. Decide required redundancy and resilience posture for storage and state.

Done looks like: Region and resilience choices are documented in your environment standards.

## Deployment-time inputs

### Choose key_vault_recovery_mode for each run

Why deferred: Whether a soft-deleted vault exists is runtime state, not static generation input.

Source: SKILL.md deploy-infrastructure key vault state-machine requirements.

Resolution:
1. Use auto for normal reruns.
2. Use recover only when a specific recoverable vault is expected.
3. Use fresh only when no recoverable vault exists.

### Choose state_strategy for each run

Why deferred: State strategy depends on whether reruns are destructive reset runs or preservation runs.

Source: SKILL.md deploy-infrastructure state strategy policy.

Resolution:
1. Use fail for non-destructive runs.
2. Use recreate_rg only for disposable dev reruns.

### Resolve article-missing workload specifics

Why deferred: The source article leaves several runtime specifics unspecified.

Source: SPEC.md sections with not stated in article values.

Resolution:
1. Define source systems and data formats for Bronze ingestion.
2. Define concrete catalog/schema names and naming policy beyond generated defaults.
3. Define schedules/SLAs and alerting thresholds for each job.
4. Define explicit network controls for workspace and data-plane resources.
5. Define concrete monitoring retention and disaster recovery requirements.

### Traceability index for unspecified article values

Why deferred: The source article intentionally leaves environment-specific values open; these must be supplied by operators.

Source: SPEC.md section Architecture (data volume/frequency/latency not stated in article).
Source: SPEC.md section Azure services (private endpoint and VNet specifics not stated in article).
Source: SPEC.md section Azure services (region and redundancy not stated in article).
Source: SPEC.md section Databricks (workspace tier not stated in article).
Source: SPEC.md section Databricks (schema naming specifics not stated in article).
Source: SPEC.md section Databricks (metastore identifier not stated in article).
Source: SPEC.md section Databricks (runtime, libraries, init scripts not stated in article).
Source: SPEC.md section Data model (source systems and formats not stated in article).
Source: SPEC.md section Data model (partitioning strategy not stated in article).
Source: SPEC.md section Data model (liquid clustering or Z-ordering strategy not stated in article).
Source: SPEC.md section Data model (schema evolution rules not stated in article).
Source: SPEC.md section Data model (data quality test rules not stated in article).
Source: SPEC.md section Security and identity (exact role assignments and grants not stated in article).
Source: SPEC.md section Security and identity (network topology details not stated in article).
Source: SPEC.md section Operational concerns (budget and reserved-capacity specifics not stated in article).
Source: SPEC.md section Operational concerns (backup, retention, DR specifics not stated in article).

Resolution:
1. Review each referenced SPEC.md section and assign an explicit environment value or policy decision.
2. Record approved values in platform standards and propagate them to workflow inputs, Terraform variables, and runbooks.

## Post-infrastructure

### Create AKV-backed Databricks secret scope and populate runtime secrets

What this is: Jobs rely on runtime secret retrieval through dbutils and a Databricks secret scope backed by Azure Key Vault.

Why deferred: Secret values and scope wiring are environment-specific operator actions.

Source: SPEC.md Security and identity; article secrets and credentials guidance.

Resolution:
1. Create a Databricks secret scope backed by generated Key Vault.
2. Add runtime secret keys required by source connectors and downstream outputs.
3. Validate secret reads in non-production workspace first.

Done looks like: Bronze job secret lookup succeeds without missing-secret errors.

### Configure Unity Catalog grants and external location permissions

What this is: Per-layer identities need UC and storage privileges aligned with least-privilege boundaries.

Why deferred: Exact privilege matrix depends on tenant policy and data products.

Source: SPEC.md Security and identity; article Lakeflow configuration.

Resolution:
1. Grant each layer principal only required read/write privileges for its layer transitions.
2. Verify access connectors have required storage data-plane permissions.
3. Validate no cross-layer write privileges are accidentally granted.

Done looks like: Bronze cannot write Silver/Gold targets; Silver cannot write Gold unless intended transition.

## Post-DAB

### Run orchestrator functional verification

What this is: Validate setup, bronze, silver, gold, and smoke-test sequence end-to-end.

Why deferred: Requires deployed infrastructure, configured secrets, and source data.

Source: SKILL.md optional functional test requirement.

Resolution:
1. Trigger orchestrator job.
2. Verify expected target tables are created and populated.
3. Capture and resolve any identity, catalog, or secret access failures.

Done looks like: Full task chain succeeds and smoke test minimum-row assertion passes.

## Architectural decisions deferred

### Remote Terraform backend adoption

What this is: Current baseline is local/ephemeral state in workflow runs.

Why deferred: Backend storage and governance setup is a platform decision outside this generation pass.

Source: terraform skill State Management guidance.

Resolution:
1. Decide backend strategy for non-destructive long-lived environments.
2. Implement backend configuration and state migration plan.

Done looks like: Reruns preserve state safely without requiring recreate_rg strategy.

### Detailed networking hardening

What this is: The article emphasizes isolation but does not define full private endpoint and VNet injection topology.

Why deferred: Supporting infrastructure is substantial and must be planned as a full feature family.

Source: SPEC.md Azure Services and Security sections (not stated in article entries).

Resolution:
1. Decide whether to adopt private endpoints and full VNet injection for Databricks and supporting services.
2. Add complete supporting infrastructure in one module iteration to avoid partial family misconfiguration.

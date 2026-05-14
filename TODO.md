# TODO - blg dev

This file tracks unresolved decisions and manual actions for the generated secure Medallion baseline.

## Pre-deployment

### Confirm workspace tier and workspace network posture

What this is: The article focuses on security outcomes and isolation goals, but does not lock exact Azure Databricks SKU and full network hardening topology.

Why deferred: These choices are tenant and cost-policy specific and must match enterprise controls.

Source: SPEC.md section Databricks.

Resolution:
1. Choose workspace SKU and document the rationale.
2. Decide whether to remain on the generated public-access baseline or move to private-network hardening.
3. Align workspace settings with organization policy before production rollout.

Done looks like: The chosen SKU and workspace network posture are approved and documented for the target environment.

### Confirm region redundancy and disaster posture

What this is: The article does not provide LRS/ZRS/GRS choices or regional failover pattern.

Why deferred: Redundancy and disaster posture are organization-level architecture decisions.

Source: SPEC.md section Azure Services.

Resolution:
1. Select redundancy by data criticality and recovery objectives.
2. Document target recovery expectations and data-protection boundaries.

Done looks like: Storage redundancy and DR position are explicitly defined for the workload.

### Validate source-system contract for Bronze ingestion

What this is: The article describes the layered model, but does not provide concrete source systems, payload formats, or ingestion timing contract.

Why deferred: These depend on upstream systems external to this repository.

Source: SPEC.md section Data Model.

Resolution:
1. Confirm source systems and expected schema contracts.
2. Define ingestion cadence and acceptable lateness.
3. Record source ownership and handoff responsibilities.

Done looks like: Bronze input contracts and cadence are approved by source owners.

## Deployment-time inputs

### Choose key-vault recovery mode per run

Why deferred: The correct value depends on whether a soft-deleted vault exists for the target name.

Source: SPEC.md section Operational Concerns.

Resolution:
1. Use auto as baseline.
2. Use recover only when recovery is required.
3. Use fresh only when no soft-deleted vault with matching name exists.

### Choose state strategy per run

Why deferred: The right behavior depends on whether the run is destructive reset or non-destructive adoption.

Source: SPEC.md section Operational Concerns.

Resolution:
1. Use fail when preserving existing resources is required.
2. Use recreate_rg only for disposable dev reruns.

### Pick runtime and clustering settings per layer

Why deferred: Runtime version and Photon tuning are discussed conceptually but exact values are not fixed by the article.

Source: SPEC.md section Databricks.

Resolution:
1. Select runtime versions for Bronze, Silver, and Gold based on validation policy.
2. Set cluster-policy guardrails per layer.
3. Confirm autoscaling and auto-termination defaults.

Done looks like: Layer runtimes and cluster-policy parameters are approved and repeatable.

### Define scheduling and concurrency policy

Why deferred: Trigger mode and concrete schedules are not stated in the article.

Source: SPEC.md section Databricks.

Resolution:
1. Choose orchestrator schedule and retry semantics.
2. Define concurrency and backfill behavior per layer.

Done looks like: Job schedule and retry/concurrency rules are documented and applied.

## Post-infrastructure

### Create AKV-backed Databricks secret scope

What this is: Jobs expect a Key Vault-backed scope and runtime secret retrieval path.

Why deferred: Scope creation requires the workspace and vault to already exist.

Source: SPEC.md section Security And Identity.

Resolution:
1. Create one secret scope for the environment.
2. Bind it to the generated Key Vault.
3. Validate secret-read access in non-production first.

Done looks like: The expected scope exists and resolves secrets from the correct vault.

### Populate runtime secrets

What this is: Source credentials and API keys are intentionally excluded from generated code.

Why deferred: Secret values must be supplied by operators and never embedded in repo artifacts.

Source: SPEC.md section Security And Identity.

Resolution:
1. Collect required keys from entrypoint secret-read usage.
2. Store secret values in Azure Key Vault with stable key names.
3. Validate no secret value is logged by job code.

Done looks like: All required keys exist and jobs run without missing-secret failures.

### Finalize Unity Catalog grants and ownership

What this is: The architecture requires strict principal-scoped grants per layer.

Why deferred: Exact grants depend on environment governance and downstream consumer model.

Source: SPEC.md section Security And Identity.

Resolution:
1. Assign browse/read/write privileges per layer boundary.
2. Confirm owner model for catalogs and schemas.
3. Review grants against least-privilege policy.

Done looks like: Layer jobs run successfully without privilege errors and without cross-layer overreach.

## Post-DAB

### Run orchestrator end-to-end validation

What this is: A deployed bundle does not prove runtime data flow correctness until jobs execute.

Why deferred: This depends on completed identity, secrets, UC grants, and source availability.

Source: SPEC.md section Architecture.

Resolution:
1. Execute orchestrator job and inspect each layer run.
2. Verify Bronze, Silver, and Gold tables are created or updated.
3. Validate smoke test minimum row-count gate.

Done looks like: Full run succeeds with expected tables and no identity/secret/storage failures.

### Establish observability dashboards and alerts

What this is: The article recommends system-table and job-UI observability, but concrete alert rules are not fully specified.

Why deferred: Alert routing and threshold policy are operational decisions.

Source: SPEC.md section Operational Concerns.

Resolution:
1. Enable and grant access to system tables used for job and cost analysis.
2. Define actionable alert thresholds for failure, duration, and spend.
3. Configure run notifications by environment.

Done looks like: Teams receive actionable alerts and can query reliability and cost by layer.

## Architectural decisions deferred

### Decide managed-table lifecycle and retention conventions

What this is: Managed tables are selected, but retention, vacuum, and table-lifecycle policy are not fully specified.

Why deferred: Data-governance policy varies across organizations.

Source: SPEC.md section Data Model.

Resolution:
1. Define retention and cleanup expectations by layer.
2. Define maintenance cadence for lifecycle operations.
3. Align with compliance policy before production.

Done looks like: Managed-table lifecycle policy is documented and auditable.

### Move from ephemeral state operation to durable state strategy

What this is: Ephemeral-state reruns are supported by workflow controls, but long-lived environments need durable state management.

Why deferred: Backend/state governance is platform-level and may require shared infra standards.

Source: SPEC.md section Operational Concerns.

Resolution:
1. Choose and approve durable state strategy for non-ephemeral environments.
2. Adopt the chosen state approach before production change cadence.

Done looks like: Non-destructive reruns are safe and repeatable for long-lived environments.
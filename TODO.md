# TODO - blg dev

This file tracks unresolved deployment decisions and post-deployment actions for the generated secure medallion baseline.

## Pre-deployment

### Confirm target Azure region and redundancy policy
**What this is.** The source article does not prescribe a specific Azure region or storage redundancy model, but these choices affect compliance, latency, and cost.

**Why deferred.** Region and redundancy are tenant-specific governance decisions and were marked as not stated in article.

**Source.** SPEC.md - Azure services (region and redundancy).

**Resolution.**
1. Select the approved Azure region for this workload according to enterprise policy.
2. Select storage redundancy policy (LRS, ZRS, GRS) per environment risk profile.
3. Align Terraform variable defaults and deployment workflow inputs with these approved values.

**Done looks like.** An approved region and redundancy model are documented and used consistently in deployment runs.

### Confirm workspace tier and networking controls
**What this is.** The architecture requires secure Databricks deployment and least privilege, but does not specify full workspace SKU/network controls.

**Why deferred.** The source article is conceptual for Part I and does not provide full workspace networking matrices.

**Source.** SPEC.md - Databricks and Azure services networking posture.

**Resolution.**
1. Confirm the Databricks workspace tier for dev and production environments.
2. Decide whether private endpoints are required for storage, key vault, and workspace control plane.
3. Define firewall and egress restrictions that satisfy security policy.

**Done looks like.** Workspace SKU and network model are approved and reflected in Terraform configuration.

### Confirm deployment principal permissions and identity mode
**What this is.** The deployment principal must provision Azure resources and role assignments; layer identities are either created or reused based on mode.

**Why deferred.** Tenant permission boundaries vary and cannot be inferred from the article.

**Source.** SPEC.md - Security and identity.

**Resolution.**
1. Verify deployment principal has Contributor and User Access Administrator at deployment scope.
2. For layer_sp_mode=create, verify directory permissions allow managed identity/app operations as required by tenant policy.
3. For restricted tenants, switch to existing mode and provide existing layer principal identifiers.

**Done looks like.** The selected identity mode runs without RBAC or directory authorization failures.

## Deployment-time inputs

### Select key_vault_recovery_mode at dispatch time
**Why deferred.** Soft-delete state is environment-specific and cannot be predetermined by generation logic.

**Source.** SPEC.md - Operational concerns and out-of-scope markers.

**Resolution.**
1. Use auto for normal runs.
2. Use recover when a soft-deleted vault is known to exist.
3. Use fresh only when no soft-deleted vault exists.

### Select state_strategy per run intent
**Why deferred.** Ephemeral-state rerun strategy depends on whether a clean rebuild is desired.

**Source.** SPEC.md - Operational concerns.

**Resolution.**
1. Use fail for non-destructive and production-aligned runs.
2. Use recreate_rg only for disposable development reruns.

### Provide unresolved runtime values not stated in article
**What this is.** Several runtime values were explicitly not stated in article and must be supplied at deployment.

**Why deferred.** The orchestrator does not invent production values for source systems, schedules, or grants.

**Source.** SPEC.md - Databricks, Data model, Security and identity.

**Resolution.**
1. Provide source system endpoints and source data format contracts.
2. Provide concrete job schedules, trigger frequencies, and concurrency expectations.
3. Provide catalog.schema names where organizational standards differ from defaults.
4. Provide explicit RBAC and Unity Catalog grant matrices for human and service identities.

**Done looks like.** Workflow dispatch and post-deploy setup have no missing-value blockers.

## Post-infrastructure

### Create AKV-backed Databricks secret scope and populate runtime keys
**What this is.** Workloads must read secrets at runtime via Databricks secret scope mapped to Azure Key Vault.

**Why deferred.** Secret values must never be embedded in generated code or workflows.

**Source.** SPEC.md - Security and identity.

**Resolution.**
1. Create the Databricks secret scope backed by the provisioned Key Vault.
2. Populate all workload runtime secret keys required by layer code.
3. Validate secrets are readable in a non-production workspace.

**Done looks like.** Job runs do not fail on missing secret scope or secret keys.

### Apply Unity Catalog grants and access connector verification
**What this is.** Least privilege requires explicit grants for layer principals and verified connector access.

**Why deferred.** Exact privilege matrix is not stated in article and depends on target consumers.

**Source.** SPEC.md - Security and identity; Databricks.

**Resolution.**
1. Grant USE/SELECT/MODIFY privileges per layer principal and table flow.
2. Verify access connector identities have storage data-plane permissions per layer.
3. Validate each layer can read only allowed upstream data and write only allowed targets.

**Done looks like.** Layer jobs pass with no insufficient-privileges failures and isolation boundaries are enforced.

## Post-DAB

### Run orchestrator functional verification
**What this is.** Deployment success does not guarantee runtime behavior; full job chain execution must be verified.

**Why deferred.** Functional testing requires deployed infrastructure, credentials, and source data readiness.

**Source.** SPEC.md - Architecture and operational concerns.

**Resolution.**
1. Trigger orchestrator run in deployed workspace.
2. Verify setup, bronze, silver, gold, and smoke-test tasks succeed in sequence.
3. Validate expected layer tables are created and populated.

**Done looks like.** End-to-end medallion run succeeds with expected table outputs.

## Architectural decisions deferred

### Configure durable remote Terraform state for non-destructive reruns
**What this is.** Local/ephemeral state is sufficient for baseline generation but not ideal for persistent team operations.

**Why deferred.** Backend and state-locking design is an environment governance decision.

**Source.** SPEC.md - Operational concerns.

**Resolution.**
1. Provision a shared Terraform backend with locking.
2. Migrate state and align workflow behavior for incremental updates.
3. Keep recreate_rg for emergency disposable environments only.

**Done looks like.** Repeated deployments operate incrementally without state-loss conflict patterns.

### Define observability and alert policies with thresholds
**What this is.** The article mandates observability enablement but does not define alert thresholds, routing, or SLO targets.

**Why deferred.** Alert strategy is operations-team specific and not provided in article.

**Source.** SPEC.md - Operational concerns.

**Resolution.**
1. Define failure, latency, and spend thresholds per layer.
2. Route alerts to ownership channels with on-call expectations.
3. Review diagnostic retention and audit trail requirements.

**Done looks like.** Monitoring produces actionable alerts with clear ownership and retention controls.

# TODO - blg tst

## Pre-deployment

### Confirm Entra directory permissions for create mode

Why deferred. This deployment uses layer_sp_mode=create, which requires creating app registrations and service principals in Entra ID.
Source. SPEC.md Security and identity.
Resolution.
1. Confirm the deployment principal can create app registrations and enterprise applications in the tenant.
2. If tenant policy blocks this, switch to existing mode and pre-provision layer principals.
Done looks like. Infrastructure deploy in create mode completes without Authorization_RequestDenied errors.

### Define region and naming governance exceptions

Why deferred. The article does not define enterprise naming exceptions or policy waivers.
Source. SPEC.md Azure services.
Resolution.
1. Validate blg/tst/uks naming with platform governance.
2. Approve or document required exceptions before production.
Done looks like. Resource naming passes policy checks for the target subscription.

## Deployment-time inputs

### Select state strategy per run

Why deferred. Local ephemeral state behavior depends on whether this is a clean-slate or adopt-existing run.
Source. Skill workflow input contract.
Resolution.
1. Use fail for non-destructive runs.
2. Use recreate_rg only when destructive rebuild is intended.
Done looks like. Workflow preflight behavior matches deployment intent.

### Select key vault recovery mode per run

Why deferred. Soft-delete state cannot be known reliably at generation time.
Source. Skill workflow input contract.
Resolution.
1. Use auto as default.
2. Use recover or fresh only when operating state is already known.
Done looks like. Key Vault provisioning path succeeds without manual rerun loops.

## Post-infrastructure

### Create Databricks Key Vault-backed secret scope

Why deferred. Scope creation occurs inside workspace runtime, not Terraform infrastructure provisioning.
Source. SPEC.md Security and identity.
Resolution.
1. Create the secret scope mapped to the deployed Key Vault.
2. Validate workspace principals can read required secret keys.
Done looks like. Runtime secret reads succeed from Databricks jobs.

### Populate runtime secrets and source credentials

Why deferred. Secret values are environment-owned credentials and are intentionally never generated.
Source. SPEC.md Security and identity; SPEC.md Data model.
Resolution.
1. Define exact key list for external source access.
2. Populate secrets in Key Vault and validate retrieval in workspace context.
Done looks like. Bronze ingestion job can authenticate to source systems without inline secrets.

### Finalize Unity Catalog grants and object ownership

Why deferred. The article describes secure layering but not the full grant matrix.
Source. SPEC.md Databricks; SPEC.md Security and identity.
Resolution.
1. Grant least-privilege catalog/schema/table rights for bronze, silver, and gold principals.
2. Verify owners and consumer group privileges align with governance standards.
Done looks like. Orchestrated job chain runs without UC permission errors.

## Post-DAB

### Replace scaffolded data logic with workload-specific transformations

Why deferred. Article is architectural and does not provide full source-specific transformation code.
Source. SPEC.md Data model.
Resolution.
1. Implement source ingestion logic in bronze entrypoint.
2. Implement domain transformations in silver and serving logic in gold.
3. Preserve argument contracts used by generated jobs.yml.
Done looks like. Orchestrator creates or updates expected bronze, silver, and gold datasets.

### Validate end-to-end smoke path

Why deferred. Functional verification requires deployed environment and populated runtime dependencies.
Source. Skill validation Step 9.2.
Resolution.
1. Execute orchestrator job.
2. Validate data appears across all layers with expected minimum row counts.
Done looks like. Smoke test job succeeds and confirms medallion flow integrity.

## Architectural decisions deferred

### Remote Terraform backend adoption

Why deferred. Baseline generation keeps state local for iteration speed.
Source. SPEC.md Operational concerns.
Resolution.
1. Plan remote backend for collaborative and non-destructive production deployments.
2. Migrate state before production change management starts.
Done looks like. Terraform state persists across workflow runs with locking.

### Monitoring and DR design

Why deferred. Monitoring stack and disaster recovery strategy are not stated in article.
Source. SPEC.md Operational concerns.
Resolution.
1. Select monitoring and alerting services.
2. Define retention, backup, and recovery objectives for medallion data products.
Done looks like. Operational runbook includes observability and disaster recovery controls.

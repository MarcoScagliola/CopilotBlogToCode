# TODO — blg dev

This file lists what the generated artifacts did not decide for you and what still needs to happen after deployment. Each entry is written as an operator task rather than a command recipe.

## Pre-deployment

### Confirm the deployment principal can create Entra app registrations and service principals

**What this is.** This generated baseline is the `create` identity variant. Terraform will create one Microsoft Entra ID application and one service principal per medallion layer.

**Why deferred.** Directory permissions are tenant-specific and cannot be granted by the workflow that depends on them.

**Source.** `terraform` skill — Identity Creation Restrictions; resolved run input `layer_sp_mode=create`.

**Resolution.**
1. Verify the deployment principal in GitHub Environment `BLG2CODEDEV` is allowed to create app registrations and service principals in Microsoft Entra ID.
2. If the tenant blocks this, decide whether to grant the permission or regenerate an `existing` identity variant instead.

**Done looks like.** The first infrastructure deployment passes the Entra identity creation steps without `Authorization_RequestDenied` errors.

### Choose the Azure network hardening posture beyond No Public IP compute

**What this is.** The article explicitly requires Secure Cluster Connectivity with No Public IP for compute, but it does not state whether the workspace, storage accounts, or Key Vault should also use private endpoints, service endpoints, or stricter public-network controls.

**Why deferred.** The article leaves this open, and the correct answer depends on subscription networking standards and landing-zone capabilities.

**Source.** SPEC.md § Azure services.

**Resolution.**
1. Decide whether the workspace, storage accounts, and Key Vault must stay reachable through public endpoints or be moved behind private connectivity.
2. If private connectivity is required, extend the Terraform baseline with the necessary virtual network, private endpoint, DNS, and firewall resources before first production use.

**Done looks like.** The chosen network model is documented and reflected consistently across Databricks, storage, and Key Vault.

### Choose storage redundancy for the three ADLS Gen2 accounts

**Why deferred.** The article names ADLS Gen2 and per-layer isolation but does not state LRS, ZRS, GRS, or another redundancy option.

**Source.** SPEC.md § Azure services.

**Resolution.**
1. Decide the resilience level required for Bronze, Silver, and Gold data in the target environment.
2. If the default `LRS` baseline is insufficient, update the Terraform storage-account configuration before deployment.

**Done looks like.** The selected replication strategy matches the environment’s resilience and cost policy.

### Choose the Databricks workspace tier and runtime standards

**What this is.** The article requires Unity Catalog, Lakeflow Jobs, separate clusters, and Secure Cluster Connectivity, but it does not state the workspace SKU, cluster DBR versions, or any init-script baseline.

**Why deferred.** These are platform-standardization choices, not article-stated facts.

**Source.** SPEC.md § Databricks; SPEC.md § Data model.

**Resolution.**
1. Confirm whether `premium` remains the right workspace SKU for the target subscription.
2. Choose supported DBR versions for Bronze, Silver, and Gold clusters, and decide whether any shared init or policy controls are required.
3. Update the jobs bundle if your runtime standards differ from the generated defaults.

**Done looks like.** Workspace SKU, cluster policy expectations, and runtime versions are explicitly chosen and documented.

### Define the real source systems and ingestion formats

**Why deferred.** The article discusses secure medallion mechanics but does not identify a source system, protocol, or file format.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Identify the authoritative upstream source or sources for Bronze ingestion.
2. Decide how Bronze will authenticate to them and what runtime secrets are needed.
3. Replace the sample bronze ingestion logic with the workload’s actual extract path before production use.

**Done looks like.** Bronze ingests from a real source with a defined format and authentication model.

## Deployment-time inputs

### Decide the exact catalog and schema naming convention

**Why deferred.** The article requires separate Bronze, Silver, and Gold catalogs but does not provide catalog names or schema names.

**Source.** SPEC.md § Databricks; SPEC.md § Operational concerns.

**Resolution.**
1. Review the generated defaults: `bronze_dev`, `silver_dev`, `gold_dev` with schemas `bronze`, `silver`, and `gold`.
2. Decide whether those names match the organization’s Unity Catalog naming standard.
3. If not, adjust the Terraform locals and bundle assumptions before deploying.

**Done looks like.** Catalog and schema names are settled before setup and orchestration jobs create data objects.

### Decide the job schedule, retry policy, concurrency, and notifications

**Why deferred.** The article describes the job topology but does not specify scheduling or operational policy.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Choose whether the orchestrator runs on a schedule, by external trigger, or manually.
2. Set retry behavior, concurrency limits, and notification channels for layer jobs and the orchestrator.
3. Update the generated jobs bundle once those decisions are made.

**Done looks like.** Workflow timing and failure-handling expectations are explicit and encoded in the Databricks jobs.

### Define the concrete target datasets and table names

**Why deferred.** The article names Bronze, Silver, and Gold as layers but does not define business-facing datasets or table names.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Identify which business entities the workload publishes in each layer.
2. Replace the scaffolded `orders_*` tables with workload-specific tables and schemas.
3. Align smoke-test assertions to the real target datasets.

**Done looks like.** Table names, schemas, and data contracts reflect the actual workload instead of the generated scaffold.

### Define schema-evolution and data-quality rules

**Why deferred.** The article calls for progressive data-quality checks but does not define validation logic, enforcement thresholds, or schema-evolution policy.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Decide what Bronze accepts, what Silver rejects or standardizes, and what Gold guarantees.
2. Encode those rules in the Python entrypoints and smoke-test job.
3. Decide how failures should surface operationally.

**Done looks like.** Data validation rules are explicit, implemented, and testable at runtime.

## Post-infrastructure

### Create the AKV-backed Databricks secret scope

**What this is.** The Databricks workspace must expose the Azure Key Vault through a secret scope so jobs can read credentials at runtime.

**Why deferred.** The scope is a Databricks workspace object created only after the workspace exists.

**Source.** SPEC.md § Security and identity; SPEC.md § Data model.

**Resolution.**
1. Create one Key Vault-backed secret scope for the environment.
2. Point it at the generated Azure Key Vault and keep the scope name aligned with the Terraform output `secret_scope`.

**Done looks like.** Bronze job secret reads succeed through the Databricks scope without exposing secret values.

### Populate Key Vault with the workload’s runtime secrets

**Why deferred.** The article requires secrets in Azure Key Vault but does not specify the secret inventory, and secret values must never be generated into the repository.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Populate the minimum scaffolded keys `source-system-username` and `source-system-password` if you keep the current bronze probe.
2. Add any additional workload-specific credentials the real Bronze implementation needs.
3. Keep key names consistent across environments.

**Done looks like.** Every runtime secret key referenced by the bundle exists in Key Vault and is readable through the scope.

### Add the layer service principals to Databricks and grant workspace access

**What this is.** The article explicitly requires each layer service principal to exist in the Databricks account and have workspace access before Lakeflow Jobs run under those identities.

**Why deferred.** The Azure side can create service principals, but Databricks account-level onboarding and workspace permission grants are separate control planes.

**Source.** SPEC.md § Databricks.

**Resolution.**
1. Register each generated service principal as a Microsoft Entra ID-managed principal in the Databricks account.
2. Grant each principal `User` access to the target workspace.
3. Ensure notebook and job permissions follow the per-layer isolation model.

**Done looks like.** Bronze, Silver, and Gold jobs can run under their intended service principals in the target workspace.

### Configure Unity Catalog external locations, storage credentials, and grants

**Why deferred.** The article makes this a core requirement, but the exact object names, grant model, and admin path are not encoded in the article or in Terraform.

**Source.** SPEC.md § Databricks; SPEC.md § Security and identity; SPEC.md § Azure services.

**Resolution.**
1. Create one storage credential and one external location per layer using the generated access connectors and storage accounts.
2. Grant each layer principal access only to the locations it must read or write.
3. Grant downstream read access only where the article’s Bronze-to-Silver-to-Gold flow requires it.

**Done looks like.** Unity Catalog storage access matches the least-privilege model and layer jobs can access only their intended paths.

## Post-DAB

### Replace the scaffolded Python jobs with workload-specific transformations

**Why deferred.** The article explains the secure architecture pattern but does not provide the workload logic, notebook code, or business transformations.

**Source.** SPEC.md § Databricks; SPEC.md § Data model.

**Resolution.**
1. Replace the generated sample ingestion and transformation logic with the real data-processing code.
2. Keep the same separation-of-duties pattern: one job per layer plus orchestrator.
3. Preserve runtime secret handling and explicit argument passing when adapting the code.

**Done looks like.** The orchestrator run produces the real business datasets rather than scaffolded sample tables.

### Enable observability destinations beyond Databricks-native views

**Why deferred.** The article explicitly calls for system tables and Jobs monitoring UI, but it does not state whether logs or metrics must also flow to Azure-native monitoring systems.

**Source.** SPEC.md § Operational concerns; SPEC.md § Azure services.

**Resolution.**
1. Decide whether Databricks-native observability is sufficient for dev.
2. If the environment requires centralized monitoring, integrate the workspace and related Azure resources with the chosen monitoring sink.

**Done looks like.** Operators know where to observe job health, cost, and failures in both Databricks and Azure.

### Run and verify the orchestrator end to end

**Why deferred.** Functional verification requires the infrastructure, identities, secrets, Unity Catalog setup, and bundle deployment to all exist first.

**Source.** SKILL.md Step 10.2 functional test.

**Resolution.**
1. Trigger one orchestrator run after post-infrastructure setup is complete.
2. Confirm Bronze, Silver, and Gold tasks run in order under the intended identities.
3. Validate that the expected target datasets exist and contain rows.

**Done looks like.** The orchestrator completes successfully and the target datasets are queryable.

## Architectural decisions deferred

### Decide backup, retention, and disaster-recovery posture

**Why deferred.** The article does not define backup, retention, or DR requirements.

**Source.** SPEC.md § Operational concerns.

**Resolution.**
1. Define retention requirements for Bronze, Silver, Gold, Key Vault, and workspace metadata.
2. Decide whether geo-redundancy, backup export, or secondary-region procedures are required.
3. Extend Terraform and runbooks accordingly.

**Done looks like.** Recovery objectives and retention controls are documented and implemented.

### Decide whether managed tables remain the right long-term choice

**What this is.** The article favors managed tables for the pattern, but the final workload may still require external-table ownership semantics for some datasets.

**Why deferred.** The article gives the architectural preference, not the final data-lifecycle policy for this repository’s workload.

**Source.** SPEC.md § Data model.

**Resolution.**
1. Confirm whether the workload benefits most from managed-table lifecycle and automatic optimization.
2. If any layer needs external ownership semantics, revise the setup and job logic for those datasets.

**Done looks like.** Table type decisions are intentional and consistent with storage-governance requirements.

### Move Terraform state to a remote backend before production use

**What this is.** The generated baseline validates and deploys with local-only Terraform state.

**Why deferred.** Local state is sufficient for clean generation and dev validation, but not for non-destructive long-lived operations.

**Source.** `terraform` skill — State Management.

**Resolution.**
1. Provision a remote backend for Terraform state.
2. Add backend configuration and migrate state before treating reruns as incremental deployments.
3. Retire `state_strategy=recreate_rg` for any environment that should preserve data.

**Done looks like.** Terraform state persists across workflow runs and incremental deploys no longer depend on destructive resets.
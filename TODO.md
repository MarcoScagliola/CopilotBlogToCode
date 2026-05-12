# TODO — blg dev

This file lists everything not yet resolved by the generated artifacts. Items are grouped by when they need to be addressed. Each entry explains what the action is, why the orchestrator did not do it, and what "done" looks like — at the level of concepts, not commands.

## Pre-deployment

### Deployment principal has the required Azure RBAC roles

**What this is.** The "deployment principal" is the Azure service principal whose credentials are stored in the GitHub Environment as `AZURE_CLIENT_ID` and `AZURE_CLIENT_SECRET`. It is the identity Terraform uses to provision every resource in `infra/terraform/`. The required roles are not narrow: Terraform creates resource groups, storage accounts, a Key Vault, three Databricks Access Connectors with role assignments, a Databricks workspace, and optionally Entra ID app registrations. Each of those last is a privileged operation.

**Why deferred.** RBAC assignment must happen before the first `terraform apply`. The deployment workflow itself uses the deployment principal's credentials to run; it cannot grant itself permissions it does not yet have.

**Source.** `terraform` skill — RBAC / Permission Errors.

**Resolution.**
1. Identify the deployment principal in Azure (the App Registration whose Application ID matches `AZURE_CLIENT_ID`, and its corresponding Enterprise Application object).
2. At the subscription scope, assign at minimum the `Contributor` role (to create resources) and the `User Access Administrator` role (to assign roles for the Access Connector SAMIs and layer principals).
3. Verify the assignments are in place before triggering the deployment workflow.

**Done looks like.** A role list query against the deployment principal at subscription scope returns at least `Contributor` and `User Access Administrator`. The first `terraform apply` proceeds past resource creation without `403 Forbidden` errors.

### Deployment principal has Entra ID permissions if `layer_sp_mode = create`

**What this is.** When `layer_sp_mode` is set to `create`, Terraform creates one Entra ID app registration per layer (Bronze, Silver, Gold) and the matching service principal. App registration requires permission against the Microsoft Entra ID directory — not against an Azure subscription. Many tenants restrict this to specific roles or admins.

**Why deferred.** Tenant policy may restrict app registration in ways the orchestrator cannot detect in advance.

**Source.** `terraform` skill — Identity Creation Restrictions; SKILL.md Step 5 restricted-tenant guardrails.

**Resolution.** Choose one of two paths:
1. Grant `Application.ReadWrite.All` (or a more restricted equivalent) to the deployment principal in Entra ID. Requires a Global Admin or Privileged Role Admin.
2. Set `layer_sp_mode = existing`, pre-create the layer service principals manually, and populate `EXISTING_LAYER_SP_CLIENT_ID` and `EXISTING_LAYER_SP_OBJECT_ID` in the GitHub Environment.

**Done looks like.** The deployment workflow runs to completion in `create` mode without `Authorization_RequestDenied` errors, or in `existing` mode with valid pre-created principals.

### GitHub Environment `BLG2CODEDEV` exists with all required secrets

**What this is.** A GitHub Environment is a named container inside a GitHub repository that holds secrets and variables scoped to a specific deployment target. The deployment workflows reference `BLG2CODEDEV` and read all Azure credentials from it.

**Why deferred.** GitHub Environment configuration is outside Terraform's reach. Even if the orchestrator could create it via the GitHub API, the secrets it needs to hold are credentials the orchestrator must not see.

**Source.** SKILL.md Step 6; `repo-context.md` GitHub Actions Credential Resolution.

**Resolution.**
1. In the repository's Settings → Environments, create an environment named `BLG2CODEDEV`.
2. Populate the required secrets: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SP_OBJECT_ID`.
3. If `layer_sp_mode = existing`, also populate `EXISTING_LAYER_SP_CLIENT_ID` and `EXISTING_LAYER_SP_OBJECT_ID`.
4. For every object-ID secret above, use the **Enterprise Application** object ID (Microsoft Entra ID → Enterprise applications → your app → Object ID), not the App Registration object ID.

**Done looks like.** The environment exists, contains all required secrets, and a workflow run that depends on `BLG2CODEDEV` is able to start without missing-environment errors.

### From SPEC.md § Azure services: storage redundancy tier not stated

**Why deferred.** SPEC.md § Azure services records storage replication as `not stated in article`. The Terraform code defaults to LRS. A production workload may require a higher redundancy tier.

**Source.** SPEC.md § Azure services.

**Resolution.** Decide whether LRS is acceptable for this workload and environment. If a higher tier is required, update `account_replication_type` in `infra/terraform/main.tf` for the layer storage accounts before the first apply.

### From SPEC.md § Databricks: workspace tier not stated (Premium inferred)

**Why deferred.** SPEC.md § Databricks records the workspace tier as `not stated in article — inferred Premium`. Unity Catalog requires Premium tier. The Terraform code provisions Premium; no action is required if this inference is correct. If Standard is intended, Unity Catalog cannot be used.

**Source.** SPEC.md § Databricks.

**Resolution.** Confirm that Premium SKU aligns with the workload's licensing and cost model. If Unity Catalog is not required, change `sku = "premium"` to `sku = "standard"` in `infra/terraform/main.tf` and remove Unity Catalog references from all bundle files.

## Deployment-time inputs

### `key_vault_recovery_mode` — choose per-run when dispatching the workflow

**Why deferred.** The right value depends on whether a Key Vault with the target name exists in a soft-deleted state from a prior deploy.

**Source.** SKILL.md Step 5 workflow inputs; `terraform` skill — Key Vault Soft-Delete Recovery.

**Resolution.** When dispatching the deployment workflow:
- Use `auto` (the default) for normal runs. The workflow checks for a soft-deleted vault and decides automatically.
- Use `recover` if you know a soft-deleted vault exists and want it recovered.
- Use `fresh` only if you are certain no soft-deleted vault exists.

### `state_strategy` — choose per-run when dispatching the workflow

**Why deferred.** This baseline keeps Terraform state ephemeral. On rerun, Terraform has no state and treats every existing Azure resource as unmanaged.

**Source.** SKILL.md Step 5 state-strategy policy.

**Resolution.** When dispatching the deployment workflow:
- Use `fail` (the default) for any run where existing resources must be preserved.
- Use `recreate_rg` only for ephemeral dev runs where you accept full deletion and recreation.

**Done looks like.** The choice matches the run's intent.

### Choose the right combination of dispatch inputs for your scenario

**Why deferred.** Each dispatch takes three inputs that interact: `key_vault_recovery_mode`, `layer_sp_mode`, and `state_strategy`. The right combination depends on the Azure state of the target tenant and subscription.

**Source.** SKILL.md Step 5 workflow inputs.

**Resolution.** Five scenarios cover almost every dispatch:
- **First deploy, clean tenant, allow app registrations:** `key_vault_recovery_mode=auto`, `layer_sp_mode=create`, `state_strategy=fail`.
- **First deploy, restricted tenant, pre-created SPs:** `key_vault_recovery_mode=auto`, `layer_sp_mode=existing`, `state_strategy=fail`.
- **Iterating in dev — full reset:** `key_vault_recovery_mode=auto`, `layer_sp_mode=create or existing`, `state_strategy=recreate_rg`.
- **Adopting a manually-recovered Key Vault:** `key_vault_recovery_mode=recover`, `layer_sp_mode=create or existing`, `state_strategy=fail`.
- **Production rerun with remote state:** `key_vault_recovery_mode=auto`, `layer_sp_mode=existing`, `state_strategy=fail`.

Avoid `state_strategy=recreate_rg` with `key_vault_recovery_mode=fresh` — deleting the resource group soft-deletes the vault, and `fresh` then conflicts.

### From SPEC.md § Data model: source systems and formats not stated

**Why deferred.** SPEC.md § Data model records source systems and formats as `not stated in article`. The Bronze entrypoint (`databricks-bundle/src/bronze/main.py`) has a TODO placeholder for ingestion logic that cannot be implemented without knowing the source.

**Source.** SPEC.md § Data model.

**Resolution.** Determine the source system type (JDBC, REST API, file drop, event stream, etc.) and format (CSV, JSON, Parquet, CDC, etc.). Implement the source-read logic in `src/bronze/main.py` and add the required credentials (connection strings, API tokens) to the Azure Key Vault before the first pipeline run.

### From SPEC.md § Data model: target table names not stated

**Why deferred.** SPEC.md § Data model records target table names as `not stated in article`. The layer entrypoints have TODO placeholders for table reads and writes.

**Source.** SPEC.md § Data model.

**Resolution.** Define table names for Bronze (raw), Silver (business-model), and Gold (dimensional) layers. Update the entrypoints to reference the agreed names. Consider establishing a naming convention that matches the organisation's catalog governance policy.

## Post-infrastructure

### Create the Azure Key Vault-backed Databricks secret scope

**What this is.** A Databricks secret scope is a named bridge through which code running inside the workspace reads credentials from a Key Vault. The vault was provisioned by Terraform. The scope is a separate object inside the workspace that must be wired to the vault before any job can read secrets.

**Why deferred.** Provisioning a secret scope requires a Databricks workspace to already exist. The infrastructure workflow ends just after workspace creation; this step bridges infrastructure to bundle deploy.

**Source.** `databricks-asset-bundle` skill — Scope Boundary; `repo-context.md` Deploy Bridge Variable Contract.

**Resolution.**
1. Identify the Key Vault Terraform provisioned: `kv-blg-dev-uks`.
2. Note the vault's full resource ID and its DNS hostname (the `vaultUri` property from the Azure portal or CLI).
3. In the Databricks workspace, create a secret scope of type *Azure Key Vault* named to match the `secret_scope` bundle variable (default: `kv-dev`). Provide the vault's resource ID and DNS hostname.
4. Confirm the workspace identity has `Key Vault Secrets User` on the vault (Terraform should have granted this via the access policy).

**Done looks like.** The scope `kv-dev` exists in the workspace with backend type `AZURE_KEYVAULT`, pointing at `kv-blg-dev-uks`. A test secret read from a notebook returns the expected value.

### Populate Azure Key Vault with runtime secrets the bundle reads

**What this is.** Layer jobs read source-system credentials at runtime through the secret scope. These are credentials the orchestrator cannot store in generated files — they must be placed in the Key Vault directly.

**Why deferred.** Credentials must come from the operator.

**Source.** SPEC.md § Security and identity; `databricks-asset-bundle` skill — Secret handling.

**Resolution.**
1. Identify the runtime secrets the layer jobs need. The article mentions API keys, DB passwords, and webhooks as examples; exact key names depend on the source systems chosen in the Deployment-time inputs section.
2. Add those secrets to the Azure Key Vault `kv-blg-dev-uks` using consistent key names across environments (e.g., `api-token`, `db-password`) so entrypoints do not need environment-specific branching.
3. Update the layer entrypoints to reference the agreed key names via `dbutils.secrets.get(scope=args.secret_scope, key="<key-name>")`.
4. Enable AKV diagnostic logs for audit purposes.

### Register Unity Catalog External Locations for each layer

**What this is.** Unity Catalog External Locations are named references that associate a storage path with a storage credential (the Access Connector SAMI). They are the mechanism through which managed tables written by Lakeflow jobs are physically stored in the layer's ADLS Gen2 account. Without them, Unity Catalog cannot write to the provisioned storage.

**Why deferred.** External Locations require a running workspace and the Access Connectors that Terraform provisions. The setup job (`setup_job` in `jobs.yml`) orchestrates the registration — but the setup job itself must be deployed and triggered after the workspace is provisioned.

**Source.** SPEC.md § Security and identity; article section "Lakeflow configuration".

**Resolution.**
1. After infrastructure deployment, trigger the `setup_job` from the bundle (or manually via the workspace UI) by running `databricks bundle run setup_job --target dev`.
2. The setup job registers one External Location per layer using the Access Connector resource ID and the storage account name passed as job parameters.
3. Verify the External Locations appear at *Catalog → External Data → External Locations* in the workspace UI with status "Available".
4. Verify that each layer service principal has the correct Browse, Read File, and Write File grants on its External Location.

**Done looks like.** Three External Locations exist (`bronze`, `silver`, `gold` or named per your convention), each showing the correct storage path and Access Connector credential, with status "Available".

### From SPEC.md § Security and identity: Unity Catalog privilege model not fully specified

**What this is.** The article describes the principle (each layer principal has access only to its own layer), but does not specify the exact Unity Catalog privilege grants for end-user groups, BI consumers, or the downstream serving layer.

**Why deferred.** Unity Catalog grants are a governance decision that depends on the organisation's data access policies.

**Source.** SPEC.md § Security and identity.

**Resolution.**
1. Decide which user groups or service principals should have read access to Gold (the BI/reporting consumer).
2. Decide whether Silver is accessible to data engineers or analysts for ad-hoc querying.
3. Decide whether Bronze is locked to the Bronze pipeline SP only.
4. Grant the appropriate `USE CATALOG`, `USE SCHEMA`, `SELECT`, and `MODIFY` privileges in Unity Catalog per the governance policy.

## Post-DAB

### Implement source ingestion logic in bronze/main.py

**Why deferred.** Source system type and format are not stated in the article. The entrypoint has a TODO stub.

**Source.** SPEC.md § Data model.

**Resolution.** Once the source system is known (from the Deployment-time inputs section), implement the read-from-source logic, apply technical metadata fields, and write to Bronze managed Delta tables with Liquid Clustering enabled.

### Implement Silver transformation logic in silver/main.py

**Why deferred.** Target table schema and transformation rules are not stated in the article.

**Source.** SPEC.md § Data model.

**Resolution.** Define the Silver business model (3NF or Data Vault). Implement cleansing, deduplication, and integration logic. Write to Silver managed Delta tables using MERGE INTO for CDC patterns or APPEND for full reloads.

### Implement Gold aggregation logic in gold/main.py

**Why deferred.** Target table schema and dimensional model design are not stated in the article.

**Source.** SPEC.md § Data model.

**Resolution.** Define the Gold dimensional model (fact and dimension tables or aggregated metrics). Implement the read-from-Silver and write-to-Gold logic. Optimise for BI read patterns.

### Implement smoke test assertions in smoke_test/main.py

**Why deferred.** The smoke test is a stub. It cannot be implemented until table names and runtime behaviours are defined.

**Source.** SKILL.md orchestrator post-deploy verification; SPEC.md § Operational concerns.

**Resolution.** Once table names and the pipeline is running, implement:
1. Unity Catalog existence checks for all three catalogs and schemas.
2. A secret-read assertion to verify the scope and vault are correctly wired.
3. A sample data check in Bronze (at least one row ingested) and Silver/Gold (transforms completed).
4. Exit with a non-zero code if any assertion fails, so Databricks marks the job as failed.

### Enable job schedules

**Why deferred.** Jobs are deployed in a paused state by default in development mode. Enabling schedules requires knowing the desired cadence for this workload.

**Source.** SPEC.md § Databricks — jobs and orchestration; article section "Observability & cost governance".

**Resolution.** Decide on the desired schedule for the Orchestrator job (which sequences Bronze → Silver → Gold). Update `databricks-bundle/resources/jobs.yml` to include a schedule expression for the orchestrator job, then redeploy the bundle.

### Configure cluster policies, sizes, and auto-termination

**Why deferred.** Cluster sizes, Photon settings, and auto-termination values are described conceptually in the article but not specified numerically. The generated jobs use placeholder cluster sizes.

**Source.** SPEC.md § Databricks — compute model; article section "Compute Configuration".

**Resolution.**
1. Right-size each layer cluster for its workload (Bronze: lighter; Silver: Photon-enabled compute-optimised; Gold: compute-optimised, Photon typically off).
2. Set auto-termination (in minutes) appropriate to the job cadence.
3. Create and attach cluster policies per layer in the workspace to enforce spend controls and enforce layer-appropriate runtime settings.

## Architectural decisions deferred

### Local-only Terraform state

**What this is.** This repository generates Terraform without a remote backend. Every workflow run starts with empty Terraform state. Resources previously created are invisible to the planner. The only safe reruns from a clean state are the destructive ones (`state_strategy=recreate_rg`). Non-destructive incremental updates require importing existing resources into state, which is manual and error-prone at scale.

**Why deferred.** Remote backend configuration is organisation-specific and cannot be inferred from the source article. It requires a storage account (or Terraform Cloud workspace) that exists independently of the workload being deployed — a chicken-and-egg problem for the orchestrator to solve.

**Source.** `terraform` skill — State Management.

**Resolution.** Decide on a remote backend. Two common options:
1. Azure Storage backend: provision a separate storage account (outside this Terraform module) and a container for state files. Annotate `infra/terraform/versions.tf` with the corresponding `backend "azurerm"` block.
2. Terraform Cloud: configure a workspace and add the `backend "remote"` or `cloud` block with the organisation and workspace name.

After adding the backend, run `terraform init -migrate-state` (or `-reconfigure`) to move any existing state into the new backend.

**Done looks like.** `terraform init` in `infra/terraform/` connects to the remote backend rather than using a local file. Multiple workflow runs against the same infrastructure produce correct incremental plans rather than trying to recreate already-existing resources.

### From SPEC.md § Databricks: Workspace type Hybrid not stated

**Why deferred.** The article does not specify whether the workspace should be Hybrid (VNet-injected) or the default managed-VNet configuration.

**Source.** SPEC.md § Databricks.

**Resolution.** If networking isolation beyond Secure Cluster Connectivity (SCC) is required, configure VNet injection in `infra/terraform/main.tf` by supplying the `custom_parameters` block with virtual network and subnet references. This requires pre-existing VNet and subnet resources.

### From SPEC.md § Databricks: Unity Catalog catalog and schema names not stated

**Why deferred.** The article names the pattern (bronze/silver/gold) but not the exact catalog or schema names. The generated code defaults to `bronze`, `silver`, `gold` for catalogs and `main` for schemas.

**Source.** SPEC.md § Databricks.

**Resolution.** Confirm or override the defaults. If the organisation's Unity Catalog governance uses different naming (e.g., `blg_bronze_dev`, `blg_bronze_dev.ingestion`), update the `catalogs` and `schemas` locals in `infra/terraform/locals.tf` and the corresponding defaults in `databricks-bundle/databricks.yml`.

### From SPEC.md § Databricks: Databricks Runtime version, libraries, and init scripts not stated

**Why deferred.** The article mentions DBR 15.4 LTS+ for Liquid Clustering but does not specify a pinned runtime for the generated jobs, nor required libraries or init scripts.

**Source.** SPEC.md § Databricks.

**Resolution.** Update `databricks-bundle/resources/jobs.yml` (generated by `generate_jobs_bundle.py`) to pin a specific Databricks Runtime version per layer cluster. Add library requirements (pip packages, wheel files) to the cluster definition if the entrypoints import third-party libraries. Init script paths: not applicable unless cluster-level configuration is required before job execution.

### From SPEC.md § Operational concerns: monitoring and alerting not configured

**Why deferred.** The article recommends enabling system tables and the Jobs monitoring UI but does not specify alerting thresholds, notification channels, or monitoring dashboards.

**Source.** SPEC.md § Operational concerns.

**Resolution.** Enable access to the `system` catalog in Unity Catalog for the relevant user groups. Configure job-level email notifications in `jobs.yml` for failure events. Define alerting rules over `system.lakeflow.*` and `system.billing.*` using the Databricks workspace Alerts feature or an external monitoring tool.

### From SPEC.md § Operational concerns: backup, retention, and DR not stated

**Why deferred.** The article does not address backup, data retention policies, or disaster recovery strategy.

**Source.** SPEC.md § Operational concerns.

**Resolution.** Define the retention policy for Bronze tables (append-only; decide how long to keep raw data). Decide whether Delta time-travel retention (`delta.logRetentionDuration`) should be extended beyond the default 30 days. For DR, decide whether to replicate storage across regions and whether a secondary workspace is required.

### From SPEC.md § Databricks: metastore reference not stated

**Why deferred.** The article assumes the account-level default metastore is in use but does not state the metastore ID or whether a specific metastore should be assigned to the workspace.

**Source.** SPEC.md § Databricks.

**Resolution.** Confirm that the account-level default Unity Catalog metastore covers the `uksouth` region. If a specific metastore is required (e.g., for data residency), assign it to the workspace via the Databricks Account console before running the setup job.

### From SPEC.md § Databricks: Allow Public Network Access not stated

**Why deferred.** The article specifies SCC (No Public IP) for cluster nodes but does not state whether public network access to the workspace control plane should be disabled.

**Source.** SPEC.md § Azure services — Networking posture.

**Resolution.** If the workspace must be fully private (no public access to the Databricks UI or API), add `public_network_access_enabled = false` to the `azurerm_databricks_workspace` resource in `infra/terraform/main.tf` and provision the required private endpoints. This is an advanced networking configuration not required for the base architecture.

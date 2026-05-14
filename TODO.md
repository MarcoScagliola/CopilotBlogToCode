# TODO - blg dev

## Pre-deployment

### Confirm Azure RBAC for deployment principal
Why deferred: Requires tenant/subscription administrator action.
Source: terraform skill RBAC requirements.
Resolution:
1. Ensure deployment principal has Contributor and User Access Administrator on target scope.
2. Verify role assignment visibility before running deploy workflow.

### Confirm Entra app-registration permission for create mode
Why deferred: Tenant policy is environment specific.
Source: terraform skill Identity Creation Restrictions.
Resolution:
1. Validate deployment principal can create application and service principal objects.
2. If restricted, switch to existing mode and pre-create principals.

### Provide article-missing volume/frequency/latency objectives
Why deferred: Not supplied by source architecture narrative.
Source: SPEC.md Architecture.
Resolution:
1. Define target data latency and batch cadence.
2. Record expected daily/peak data volume assumptions for cluster sizing.

### Decide networking boundary model
Why deferred: Network controls are not specified in the article.
Source: SPEC.md Azure services.
Resolution:
1. Choose public access vs private endpoints for workspace, storage, and Key Vault.
2. Record firewall and routing standards per environment.

### Choose region redundancy strategy
Why deferred: Redundancy profile is not specified in the article.
Source: SPEC.md Azure services.
Resolution:
1. Select LRS/ZRS/GRS policy per storage account by business RPO/RTO.
2. Document accepted resilience trade-off for dev.

### Pick Databricks workspace tier
Why deferred: Tier selection is not stated in the article.
Source: SPEC.md Databricks.
Resolution:
1. Confirm Standard or Premium tier requirements for governance/security features.
2. Update environment decision record.

### Define catalog/schema naming and metastore binding
Why deferred: Exact names and metastore reference are not stated.
Source: SPEC.md Databricks.
Resolution:
1. Select explicit catalog and schema names for Bronze/Silver/Gold.
2. Confirm metastore attachment strategy for the target workspace.

## Deployment-time inputs

### Create GitHub environment BLG2CODEDEV with required secrets
Why deferred: GitHub environment configuration is outside generated IaC.
Source: SKILL.md inputs and workflow credential contract.
Resolution:
1. Create environment BLG2CODEDEV.
2. Add tenant/subscription/client/object-id secrets.

### Select key_vault_recovery_mode per run
Why deferred: Depends on subscription soft-delete state.
Source: SKILL.md deploy workflow inputs.
Resolution:
1. Use auto for normal runs.
2. Use recover or fresh only when state is explicitly known.

### Select state_strategy per run
Why deferred: Depends on whether run is destructive or incremental.
Source: SKILL.md deploy workflow inputs.
Resolution:
1. Use fail for non-destructive runs.
2. Use recreate_rg only for disposable dev resets.

### Provide orchestration cadence and concurrency values
Why deferred: Schedule and concurrency are not stated in article.
Source: SPEC.md Databricks.
Resolution:
1. Define execution schedule for orchestrator and layer jobs.
2. Set max concurrency and retry policy aligned to source SLAs.

### Choose Lakeflow run mode
Why deferred: Triggered vs continuous mode is not stated.
Source: SPEC.md Databricks.
Resolution:
1. Decide pipeline mode by latency objective.
2. Align monitoring and cost guardrails to selected mode.

### Define runtime/libraries/init-script baseline
Why deferred: Runtime stack details are not stated.
Source: SPEC.md Databricks.
Resolution:
1. Select Databricks runtime version and dependency policy.
2. Decide whether init scripts are needed for governance tooling.

### Define concrete source systems and file/message formats
Why deferred: Source interfaces are not specified.
Source: SPEC.md Data model.
Resolution:
1. Identify upstream systems and ingestion contract.
2. Map data format and schema ownership per source.

### Decide partitioning/clustering optimization approach
Why deferred: Storage optimization strategy is not stated.
Source: SPEC.md Data model.
Resolution:
1. Choose whether to use liquid clustering or Z-order where applicable.
2. Document performance validation method.

## Post-infrastructure

### Create AKV-backed Databricks secret scope
Why deferred: Requires workspace to exist first.
Source: SPEC.md Security and identity.
Resolution:
1. Bind Databricks scope to provisioned Key Vault.
2. Validate read access with non-secret test key.

### Populate Key Vault runtime secrets
Why deferred: Credential values cannot be generated or committed.
Source: SPEC.md Security and identity.
Resolution:
1. Add all job-required secret keys.
2. Verify no secret values are exposed in code or job parameters.

### Implement concrete UC grant matrix
Why deferred: Exact grants are not stated in article.
Source: SPEC.md Security and identity.
Resolution:
1. Define grants per layer principal for catalog/schema/table operations.
2. Validate least-privilege boundaries through dry-run job execution.

### Define schema-enforcement and quality rules
Why deferred: Specific enforcement rules are not stated.
Source: SPEC.md Data model.
Resolution:
1. Add explicit schema checks and expectations per layer.
2. Record rejection and quarantine behavior for malformed records.

## Post-DAB

### Run orchestrator and validate Bronze/Silver/Gold outputs
Why deferred: Requires deployed workspace, permissions, and data.
Source: SKILL.md optional functional test.
Resolution:
1. Execute orchestrator once manually.
2. Confirm target tables are created and populated.

### Enable operational monitoring and alerting
Why deferred: Monitoring scope and alert channels are environment-specific.
Source: SPEC.md Operational concerns.
Resolution:
1. Enable system tables and jobs monitoring dashboards.
2. Configure alert policies for failed runs and duration anomalies.

## Architectural decisions deferred

### Select explicit network hardening implementation
Why deferred: Detailed network model is not stated in article.
Source: SPEC.md Security and identity.
Resolution:
1. Decide private-link and firewall strategy for all data-plane resources.
2. Add follow-up IaC changes after approval.

### Define cost policy and autoscale guardrails
Why deferred: Budget thresholds and sizing rules are not stated.
Source: SPEC.md Operational concerns.
Resolution:
1. Define budget ceiling and per-layer cost limits.
2. Set cluster sizing and auto-termination targets.

### Define backup/retention/disaster-recovery model
Why deferred: DR strategy is not stated in article.
Source: SPEC.md Operational concerns.
Resolution:
1. Define retention windows for raw and curated data.
2. Define restore process and test frequency.

### Define CI/CD promotion strategy
Why deferred: CI/CD details are deferred by article to Part II.
Source: SPEC.md Out-of-scope markers.
Resolution:
1. Define branch/environment promotion gates.
2. Add production approval and rollback policy.

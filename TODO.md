# TODO — blg dev

## Pre-deployment

### Deployment principal RBAC
Why deferred: external governance setup.
Source: terraform skill RBAC guidance.
Resolution:
1. Grant Contributor.
2. Grant User Access Administrator.

### Entra permissions for layer_sp_mode=create
Why deferred: tenant policy dependent.
Source: SPEC.md security identity section.
Resolution:
1. Grant app/service principal creation permission to deployment principal.
2. If denied, use layer_sp_mode=existing.

### GitHub environment BLG2CODEDEV secrets
Why deferred: external platform setup.
Source: workflow contract.
Resolution:
1. Configure AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SP_OBJECT_ID.
2. Use Enterprise Application object IDs.

## Deployment-time inputs

### key_vault_recovery_mode
Why deferred: depends on soft-delete state at runtime.
Source: deploy workflow input contract.
Resolution:
1. Default to auto.
2. Use recover/fresh when state is known.

### state_strategy
Why deferred: rerun strategy is operator intent.
Source: deploy workflow input contract.
Resolution:
1. Use fail for non-destructive runs.
2. Use recreate_rg for disposable dev resets.

### Source systems/formats not stated in article
Why deferred: missing in source blog.
Source: SPEC.md data model.
Resolution:
1. Define source systems and ingestion formats.
2. Implement Bronze ingestion accordingly.

## Post-infrastructure

### Create AKV-backed secret scope
Why deferred: requires deployed workspace and key vault.
Source: SPEC.md security section.
Resolution:
1. Create kv-dev-scope.
2. Link to generated key vault.

### Populate runtime secrets
Why deferred: secret values are operator-owned.
Source: SPEC.md security section.
Resolution:
1. Identify expected secret keys from entrypoint logic.
2. Populate values in key vault.

### Unity Catalog grants and ownership model
Why deferred: exact grant matrix not stated in article.
Source: SPEC.md Databricks/security sections.
Resolution:
1. Define ownership and grant model for bronze/silver/gold.
2. Apply least-privilege grants for layer identities.

### Implement bronze/silver/gold logic
Why deferred: source contracts not given by article.
Source: SPEC.md data model.
Resolution:
1. Implement layer transformations.
2. Add data quality and schema checks.

## Post-DAB

### End-to-end orchestrator verification
Why deferred: depends on completed setup and runtime data availability.
Source: skill functional validation guidance.
Resolution:
1. Run orchestrator.
2. Verify Bronze->Silver->Gold outputs.

## Architectural decisions deferred

### Remote Terraform state
Why deferred: baseline flow uses local ephemeral state.
Source: terraform skill state guidance.
Resolution:
1. Configure remote backend.
2. Migrate state and standardize non-destructive reruns.

### Storage shared-key hardening
Why deferred: provider compatibility during provisioning.
Source: terraform skill provider behavior guidance.
Resolution:
1. Validate identity-only access paths.
2. Disable shared key in hardening pass.

### Cluster policy and monitoring detail
Why deferred: not specified concretely in article.
Source: SPEC.md operational/Databricks sections.
Resolution:
1. Define cluster policy constraints.
2. Define monitoring and retention thresholds.

# TODO - blg dev

This file tracks decisions and setup actions that are intentionally deferred from generation. Work top-to-bottom by phase.

## Pre-deployment

### Deployment principal RBAC

- Ensure the deployment principal has at least `Contributor` and `User Access Administrator` on the target subscription.
- Verify role assignments before first infrastructure deployment.

### Entra permissions for `layer_sp_mode=create`

- Confirm the deployment principal can create app registrations and service principals in Entra ID.
- If app registration is restricted, switch to `layer_sp_mode=existing` and provide existing principal IDs.

### GitHub Environment setup

- Create or verify GitHub Environment `BLG2CODEDEV`.
- Add secrets: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SP_OBJECT_ID`.
- Add existing-layer secrets only if changing to `layer_sp_mode=existing`.

## Deployment-time inputs

### Confirm state strategy

- Decide `state_strategy`: `fail` (safe default) or `recreate_rg` (ephemeral rerun mode).
- Prefer remote backend + import for non-destructive adoption scenarios.

### Confirm Key Vault recovery mode

- Choose `key_vault_recovery_mode`: `auto`, `recover`, or `fresh`.
- Keep `auto` for most runs unless troubleshooting soft-delete edge cases.

### Data source and table specifics

- Define real source systems and ingest formats for Bronze.
- Define concrete table names and contracts for Bronze/Silver/Gold layers.

## Post-infrastructure

### Key Vault-backed Databricks secret scope

- Create AKV-backed Databricks secret scope pointing to `kv-blg-dev-uks`.
- Populate runtime secrets required by data ingestion and transformation jobs.

### Unity Catalog external locations and grants

- Register external locations for each storage account using corresponding access connectors.
- Apply least-privilege grants for layer principals and job identities.

## Post-DAB

### Implement business logic in entrypoints

- Implement ingestion logic in `databricks-bundle/src/bronze/main.py`.
- Implement transformation logic in `databricks-bundle/src/silver/main.py`.
- Implement aggregation logic in `databricks-bundle/src/gold/main.py`.
- Implement setup logic in `databricks-bundle/src/setup/main.py`.

### Enable operational hardening

- Add production-grade smoke tests in `databricks-bundle/src/smoke_test/main.py`.
- Configure schedules, retries, and alerting policies for jobs.
- Enforce cluster policies and tune cluster sizing.

## Architectural decisions deferred

- Unity Catalog metastore binding details (not stated in article).
- Monitoring and observability stack (not stated in article).
- Backup and DR approach (not stated in article).
- Data retention and lifecycle policies per layer (not stated in article).

# TODO - Secure Medallion Architecture

## Required Before First Deployment

- [ ] Confirm deployment principal has `Contributor` on the target subscription or resource group.
- [ ] Confirm deployment principal can create Entra app registrations (if using `layer_sp_mode=create`). If apply returns `Authorization_RequestDenied`:
  - Either request `Application.ReadWrite.All` for deployment principal.
  - Or keep `layer_sp_mode=existing` and reuse pre-created layer principals.
- [ ] Populate GitHub Environment `BLG2CODEDEV` with required secrets/variables:
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
  - `AZURE_SP_OBJECT_ID`
  - `EXISTING_LAYER_SP_CLIENT_ID` (required in `existing` mode)
  - `EXISTING_LAYER_SP_OBJECT_ID` (required in `existing` mode)
- [ ] Verify `AZURE_SP_OBJECT_ID` and `EXISTING_LAYER_SP_OBJECT_ID` are Enterprise Applications object IDs, not App Registration object IDs.

## Post-Infrastructure Deployment

- [ ] Confirm Databricks workspace deployment and capture successful URL/resource ID outputs.
- [ ] Create Unity Catalog catalogs:
  - `dev_bronze`
  - `dev_silver`
  - `dev_gold`
- [ ] Create schemas:
  - `dev_bronze.ingestion`
  - `dev_silver.refined`
  - `dev_gold.curated`
- [ ] Grant per-layer service principals least-privilege Unity Catalog permissions.
- [ ] Create a Key Vault-backed Databricks secret scope named `kv-dev-scope`.
- [ ] Replace sample Bronze ingestion logic in `databricks-bundle/src/bronze/main.py` with actual source ingestion.

## Security and Operations Follow-up

- [ ] Enable Azure Key Vault diagnostic logs and review access regularly.
- [ ] Configure secret rotation/expiration policies in Azure Key Vault.
- [ ] Define Databricks cluster policies per layer to constrain compute and enforce separation.
- [ ] Enable Databricks system tables and set monitoring dashboards by layer.
- [ ] Evaluate disabling shared storage key access post-deployment if tenant and provider constraints allow.

## State Management

- Current state strategy is local/ephemeral in GitHub runners.
- [ ] Add remote backend (`backend.tf`) for production state persistence.
- [ ] For repeatable dev reruns with ephemeral state, use `state_strategy=recreate_rg` in Deploy Infrastructure workflow dispatch.

## Open Architecture Inputs (not stated in article)

- [ ] Private endpoint and VNet topology details for production networking hardening.
- [ ] Region redundancy strategy (LRS/ZRS/GRS) per storage account.
- [ ] Detailed Lakeflow schedule/concurrency policy per job.
- [ ] Source system connection details and expected ingest volume/latency targets.
- [ ] Backup/retention and disaster recovery objective targets.

## Testing and Validation

- [ ] Run full deployment for `etl/dev/uksouth` and execute `orchestrator_job`.
- [ ] Verify target tables:
  - `dev_bronze.ingestion.raw_events`
  - `dev_silver.refined.events`
  - `dev_gold.curated.event_summary`
- [ ] Add smoke tests for row-count and schema integrity checks across medallion layers.
- [ ] Add `terraform fmt -check` to CI.
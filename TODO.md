# TODO — Secure Medallion Architecture

## Required Before First Deployment

- [ ] Confirm deployment principal has `Contributor` on the target subscription or resource group.
- [ ] **Confirm deployment principal can create Entra app registrations** (if using `layer_sp_mode=create`). If you see `Authorization_RequestDenied` during apply:
  - Either: Request `Application.ReadWrite.All` in Entra for the deployment principal.
  - Or: **Use `layer_sp_mode=existing` and pre-create the layer principals**, then provide their client IDs and object IDs in GitHub secrets.
- [ ] Populate GitHub Environment `BLG2CODEDEV` with all required secrets (see README).
- [ ] Verify `AZURE_SP_OBJECT_ID` and (if used) `EXISTING_LAYER_SP_OBJECT_ID` are **Enterprise Applications object IDs**, not App Registration object IDs.

## Post-Infrastructure Deployment

- [ ] Create Unity Catalog catalogs: `dev_bronze`, `dev_silver`, `dev_gold`.
- [ ] Create schemas:
  - `dev_bronze.ingestion` (for raw events)
  - `dev_silver.refined` (for deduplicated events)
  - `dev_gold.curated` (for aggregated summaries)
- [ ] Grant layer service principal IDs the appropriate Unity Catalog privileges per catalog.
- [ ] Create a Key Vault-backed secret scope named `kv-dev-scope` in the Databricks workspace.
- [ ] Replace sample Bronze ingestion logic (`databricks-bundle/src/bronze/main.py`) with actual data source extraction.

## Security & Operations Follow-up

- [ ] Enable Azure Key Vault diagnostic logs and review access regularly.
- [ ] Add secret rotation/expiration policies in Azure Key Vault.
- [ ] Add Databricks cluster policies per layer to limit compute blast radius.
- [ ] Enable Databricks system tables for job monitoring and cost visibility per layer.
- [ ] Disable `shared_access_key_enabled` on storage accounts post-deployment (if stricter zero-trust is required).

## State Management

- Terraform state is currently local/ephemeral (per GitHub Actions runner).
- **Before production use:** Configure a remote backend in `backend.tf` (Azure Storage Blob Storage recommended).
- **For iterative development:** Use `state_strategy=recreate_rg` during Deploy Infrastructure to handle ephemeral state reruns.

## Testing & Validation

- [ ] Run end-to-end deployment in `dev` and trigger the `orchestrator_job`.
- [ ] Verify all three tables exist post-run:
  - `dev_bronze.ingestion.raw_events`
  - `dev_silver.refined.events`
  - `dev_gold.curated.event_summary`
- [ ] Add smoke tests that assert table counts and schema integrity after a run.
- [ ] Add `terraform fmt -check` to CI for code style validation.
# TODO - Secure Medallion Architecture

## Required Before First Deployment

- [ ] Confirm deployment principal has `Contributor` on the target subscription or resource group.
- [ ] Confirm deployment principal has `User Access Administrator` on the target subscription when creating role assignments.
- [ ] Confirm deployment principal can create Entra app registrations if using `layer_sp_mode=create`.
  - If blocked by tenant policy, switch to `layer_sp_mode=existing` and provide existing principal IDs via GitHub secrets.
- [ ] Populate GitHub Environment `BLG2CODEDEV` with:
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
  - `AZURE_SP_OBJECT_ID`
- [ ] If using `layer_sp_mode=existing`, populate:
  - `EXISTING_LAYER_SP_CLIENT_ID`
  - `EXISTING_LAYER_SP_OBJECT_ID`
- [ ] Verify object ID secrets are Enterprise Applications object IDs, not App Registration object IDs.

## Post-Infrastructure Deployment

- [ ] In Databricks Account Console, verify Bronze/Silver/Gold service principals are added and assigned to the workspace.
- [ ] Create Unity Catalog catalogs:
  - `dev_bronze`
  - `dev_silver`
  - `dev_gold`
- [ ] Create schemas:
  - `dev_bronze.ingestion`
  - `dev_silver.refined`
  - `dev_gold.curated`
- [ ] Configure external locations and storage credentials for each layer.
- [ ] Grant UC permissions with least privilege per layer principal.
- [ ] Create Databricks secret scope backed by Key Vault: `kv-dev-scope`.
- [ ] Add required runtime secrets to Key Vault (for real Bronze ingestion connectors).

## Security and Operations Follow-up

- [ ] Define per-layer Databricks cluster policies (Bronze, Silver, Gold).
- [ ] Restrict cluster policy usage to matching service principals and groups.
- [ ] Enable Key Vault diagnostics and configure access reviews.
- [ ] Configure secret rotation in Key Vault.
- [ ] Enable Databricks system tables (`system.lakeflow`, `system.billing`) for observability and cost governance.
- [ ] Optionally harden storage by setting `shared_access_key_enabled=false` after validation.

## State Management

- [ ] Move from ephemeral local state to remote backend before production rollout.
- [ ] Add `infra/terraform/backend.tf` and bootstrap backend storage.
- [ ] Keep `state_strategy=recreate_rg` only for disposable development reruns.

## Validation and Testing

- [ ] Trigger `Validate Terraform` workflow.
- [ ] Trigger `Deploy Infrastructure` with inputs:
  - `workload=blg`
  - `environment=dev`
  - `azure_region=eastus2`
  - `layer_sp_mode=create` or `existing`
- [ ] Trigger `Deploy DAB` with the matching `infra_run_id`.
- [ ] Run `medallion-orchestrator-dev` and verify:
  - `dev_bronze.ingestion.raw_events`
  - `dev_silver.refined.events`
  - `dev_gold.curated.event_summary`

## Functional Test Status

- Status: Cloud execution pending. Local repository generation and static validation are implemented in this update.


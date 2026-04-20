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


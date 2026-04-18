# TODO — Secure Medallion Architecture

## Required Before First Deployment

- [ ] Confirm deployment principal has `Contributor` on the target subscription or resource group.
- [ ] Confirm deployment principal can create Entra app registrations and service principals (needed for `layer_sp_mode=create`). If not, pre-create principals and use `layer_sp_mode=existing`.
- [ ] Populate GitHub Environment `BLG2CODEDEV` with all required secrets (see README).
- [ ] Verify `AZURE_SP_OBJECT_ID` and (if used) `EXISTING_LAYER_SP_OBJECT_ID` are **Enterprise Applications object IDs**, not App Registration object IDs.

## Data and Catalog Setup (Post-Infrastructure)

- [ ] Create Unity Catalog catalogs: `dev_bronze`, `dev_silver`, `dev_gold`.
- [ ] Create schemas: `ingestion` in bronze, `refined` in silver, `curated` in gold.
- [ ] Grant layer service principals the appropriate Unity Catalog privileges per catalog.
- [ ] Create a Key Vault-backed secret scope named `kv-dev-scope` in the Databricks workspace.
- [ ] Replace sample bronze ingestion logic with actual source extraction.

## Security Follow-up

- [ ] Enable Key Vault diagnostic logs and review access regularly.
- [ ] Add secret rotation/expiration policies in Key Vault.
- [ ] Add Databricks cluster policies per layer to limit compute blast radius.
- [ ] Enable Databricks system tables for job monitoring and cost visibility per layer.

## State Management

- Terraform state is currently local/ephemeral (per GitHub Actions runner).
- Before production use: configure a remote backend (Azure Storage) in `backend.tf`.
- If rerunning apply from scratch: delete the resource group first or run `terraform destroy`.

## Testing and Validation

- [ ] Run end-to-end deployment in `dev` and trigger `orchestrator_job`.
- [ ] Add smoke tests that assert tables exist in bronze/silver/gold after a run.
- [ ] Add `terraform fmt -check` to CI.

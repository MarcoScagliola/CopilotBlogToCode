# TODO - Secure Medallion Architecture

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

## Additional Service Principals (If Required By Architecture)

- [ ] If the selected architecture requires service principals beyond the base deployment/layer principals, create them in Microsoft Entra ID and document each principal purpose.
- [ ] For each additional principal, assign minimum required Azure RBAC and Databricks/Unity Catalog permissions.
- [ ] Retrieve and record for each principal:
  - Client ID (Application ID)
  - Service Principal Object ID (Enterprise Applications -> Object ID)
- [ ] Add any required IDs/secrets to GitHub Environment `BLG2CODEDEV` and update workflow/template mappings if needed.

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

## Functional Test Run Status

- Status: Blocked locally until cloud prerequisites are completed (infrastructure deploy, Unity Catalog setup, and Databricks bundle deploy).
- Run instructions once prerequisites are ready:
  1. Trigger `Deploy Infrastructure` workflow.
  2. Complete Unity Catalog and secret-scope setup listed above.
  3. Trigger `Deploy DAB` workflow.
  4. Run `orchestrator_job` in Databricks.
  5. Confirm Bronze/Silver/Gold tables are created or updated.


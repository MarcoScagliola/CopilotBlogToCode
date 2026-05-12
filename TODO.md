# TODO — blg dev (Secure Medallion)

Deferred decisions and post-deploy hardening items that require a live
Databricks workspace, domain knowledge not available from the article, or
deliberate operator action.

---

## Unity Catalog setup (requires running workspace)

- [ ] Attach the Databricks workspace to a Unity Catalog metastore.
- [ ] Create External Locations for each layer (Bronze, Silver, Gold) pointing
  to the ADLS Gen2 storage accounts, using the Access Connector credentials.
- [ ] Grant `CREATE CATALOG` on the metastore to the deployment principal.
- [ ] Run the Setup job to create catalogs and schemas.
- [ ] Grant appropriate Unity Catalog privileges to each layer service principal
  (e.g. `USE CATALOG`, `USE SCHEMA`, `CREATE TABLE`, `SELECT`).

---

## Compute hardening

- [ ] Define a cluster policy for each layer job (instance type, autoscaling
  bounds, Spark version, init scripts).
- [ ] Set Databricks Runtime version explicitly in `jobs.yml` once a target
  version has been selected.
- [ ] Evaluate cost vs. performance for job cluster vs. serverless compute.

---

## Networking hardening

- [ ] Evaluate VNet injection or Private Link for the Databricks workspace
  (article did not specify; Secure Cluster Connectivity is the baseline).
- [ ] If VNet injection is required, add `virtual_network_id`,
  `public_subnet_name`, and `private_subnet_name` to the
  `azurerm_databricks_workspace.main` custom_parameters block and provision
  the VNet/subnets in Terraform.
- [ ] Lock down ADLS Gen2 storage accounts with network rules (allowed VNets,
  private endpoints) once cluster IP ranges are known.

---

## Storage hardening

- [ ] Disable shared access keys on storage accounts once managed identities
  are verified working:
  `shared_access_key_enabled = false`
- [ ] Enable storage account diagnostic logs and retention policies.
- [ ] Review ADLS Gen2 redundancy tier (LRS is the generated default).

---

## Key Vault hardening

- [ ] Enable Azure Key Vault diagnostic logs.
- [ ] Consider enabling purge protection for production environments.
- [ ] Review and tighten Key Vault access policies once layer service
  principal object IDs are confirmed.
- [ ] Rotate layer service principal client secrets and store them in Key Vault.

---

## Service principal hardening

- [ ] Generate client secrets for each layer service principal (created by
  Terraform but secrets not generated — use `azuread_application_password`
  or rotate manually post-deploy).
- [ ] Store client secrets in Key Vault for runtime secret scope access.

---

## CI/CD and observability

- [ ] Add schedule triggers to `deploy-dab.yml` for recurring pipeline runs.
- [ ] Enable Databricks system tables (`system.lakeflow.*`, `system.billing.*`)
  for pipeline monitoring and cost attribution.
- [ ] Configure alerting on job failure via Databricks notification destinations.
- [ ] Complete Part II of the article series for CI/CD hardening guidance.

---

## Data model

- [ ] Define source systems, ingestion formats, and Bronze table schemas.
- [ ] Define Silver conformed model entity/table names and transformation rules.
- [ ] Define Gold dimensional model and aggregation logic.
- [ ] Implement entrypoints (`src/<layer>/main.py`) — currently stub only.
- [ ] Implement smoke test assertions in `src/smoke_test/main.py`.

---

## Production environment

- [ ] Create a `prd` GitHub Environment and configure equivalent secrets.
- [ ] Review resource SKUs/tiers for production sizing.
- [ ] Enable geo-redundant storage (GRS/GZRS) for production storage accounts.
- [ ] Enable soft-delete and versioning on ADLS Gen2 for production.

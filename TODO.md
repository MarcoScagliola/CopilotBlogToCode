# TODO

## Pre-deployment
- Confirm the deployment service principal has rights to create resource groups, storage, Databricks, and role assignments.
- Decide whether to keep `layer_sp_mode=create` or switch to `layer_sp_mode=existing` for restricted tenants.
- If using existing mode, provide Enterprise Application object IDs for existing layer principals.

## Deployment-time inputs
- Validate workflow dispatch values: `workload`, `environment`, `azure_region`.
- Choose `state_strategy`:
  - `fail` for safe non-destructive retries.
  - `recreate_rg` only for ephemeral environments.
- Choose `key_vault_recovery_mode` (`auto` recommended).

## Post-infrastructure
- Create an Azure Key Vault-backed Databricks secret scope named from Terraform output `secret_scope_name`.
- Add runtime secret key `source-system-token` in Key Vault.
- Verify Databricks workspace can read the secret scope.
- Grant Unity Catalog privileges to operational personas as needed.

## Post-DAB
- Run `orchestrator_job` and verify all five jobs complete.
- Validate expected tables exist in Bronze, Silver, and Gold schemas.
- Validate monitoring and alerting settings for production operations.

## Architectural decisions deferred
- Select remote Terraform backend for team/state durability.
- Enforce production cluster policies and budget controls.
- Replace seed Bronze ingestion with real source connectors and credential rotation policy.
- Finalize private networking and data exfiltration controls for production.

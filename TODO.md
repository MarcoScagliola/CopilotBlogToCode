# TODO

## Pre-deployment
- Confirm the deployment service principal can create resource groups, Azure Databricks, storage accounts, Key Vault, and RBAC assignments.
- Decide whether to keep `layer_sp_mode=create` or use `layer_sp_mode=existing` for restricted tenants.
- If using existing mode, prepare the Enterprise Application object ID and client ID for the shared layer principal.

## Deployment-time inputs
- Validate workflow inputs for workload, environment, and azure_region.
- Choose `state_strategy` based on state persistence:
  - `fail` for non-destructive adoption.
  - `recreate_rg` only for ephemeral environments.
- Use `key_vault_recovery_mode=auto` unless you need explicit recovery behavior.

## Post-infrastructure
- Create an Azure Key Vault-backed Databricks secret scope using the Terraform `secret_scope_name` output.
- Add the `source-system-token` secret into Azure Key Vault.
- Verify Databricks can resolve and read the secret scope.
- Apply Unity Catalog grants required by your data producers and consumers.

## Post-DAB
- Run the orchestrator job and verify all layer jobs succeed.
- Validate Bronze, Silver, and Gold tables exist and contain expected data.
- Configure production monitoring, alerting, and budget controls.

## Architectural decisions deferred
- Choose a remote Terraform backend for persistent team state.
- Define production networking and exfiltration controls.
- Replace seed Bronze ingestion with real source integrations.
- Finalize production cluster policy, observability, and cost-governance settings.

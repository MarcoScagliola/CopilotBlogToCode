## Manual setup after Terraform deploy

1. Create an AKV-backed Databricks secret scope for the value exported as `secret_scope_name`.
2. Add the runtime secret key `source-system-token` to Azure Key Vault.
3. Verify the Databricks workspace can read the Key Vault-backed scope.
4. Grant Unity Catalog permissions for the execution identities if your environment requires explicit catalog grants beyond the sample setup job.
5. Run the `Deploy DAB` workflow using the successful infrastructure run ID.

## If `layer_sp_mode=existing`

1. Provide `EXISTING_LAYER_SP_CLIENT_ID`.
2. Provide `EXISTING_LAYER_SP_OBJECT_ID`.
3. Ensure that principal has storage access and Key Vault read access for all required layers.
4. Ensure the object ID comes from Microsoft Entra ID Enterprise Applications, not App Registrations.

## Recommended production follow-up

1. Move Terraform state to a remote backend.
2. Add cluster policies and tighter sizing controls.
3. Replace the sample Bronze ingestion with the real upstream source.
4. Enable Databricks system tables, cost dashboards, and alerts.
5. Implement private networking and stricter ingress controls if your tenant requires them.
6. Add rotation policy reviews and Key Vault diagnostics.

## Open implementation decisions

1. Confirm whether layer identities should remain `create` or switch to `existing` by default.
2. Confirm the real Bronze source protocol and schema.
3. Confirm whether the workspace should be upgraded to a stricter no-public-network topology in a follow-on iteration.

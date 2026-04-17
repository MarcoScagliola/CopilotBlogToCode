# TODO — Unresolved Values

## GitHub Environment Secrets
Set these in GitHub Environment `BLG2CODEDEV`:
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID` when using `layer_sp_mode=existing`

## Azure Prerequisites
- Unity Catalog metastore must already exist and be associated with the workspace/account context
- deployment identity needs subscription-level Azure RBAC suitable for provisioning resources and role assignments
- restricted tenants may require the `existing` identity mode instead of per-layer Entra app creation

## Post-Infrastructure Setup
After Terraform succeeds:
- populate Azure Key Vault with `jdbc-host`, `jdbc-database`, `jdbc-user`, and `jdbc-password`
- create the Databricks AKV-backed secret scope named by Terraform output `secret_scope_name`
- validate Databricks workspace access and Unity Catalog behavior
- then run the DAB deployment workflow

## Operational Follow-Up
- consider adding a remote Terraform backend for persistent state across workflow runs
- review whether per-layer identities or the shared compatibility mode are appropriate for the target tenant
- harden storage-account settings after validating provider compatibility in the target tenant if stricter posture is required

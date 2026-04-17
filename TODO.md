# TODO

## Required GitHub Environment Secrets or Variables (BLG2CODEDEV)
- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET
- AZURE_SP_OBJECT_ID

## Conditional Secrets or Variables (only if layer_sp_mode=existing)
- EXISTING_LAYER_SP_CLIENT_ID
- EXISTING_LAYER_SP_OBJECT_ID

## Required RBAC / Entra Permissions
- Contributor on target subscription/resource group
- User Access Administrator for role assignments
- Application.ReadWrite.All or Directory.ReadWrite.All when creating Entra applications

## Post-Deploy Secret Setup in Key Vault
Populate the following secrets in the provisioned Key Vault:
- jdbc-host
- jdbc-database
- jdbc-user
- jdbc-password

## State Management Note
If CI uses local ephemeral Terraform state, reruns may fail with already-existing resources. Either:
- delete previous resources before rerun, or
- configure remote backend for persistent state.

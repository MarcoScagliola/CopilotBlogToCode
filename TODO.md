# TODO – Unresolved Values and Prerequisites

## Before Running Any Workflow

### GitHub Environment: `BLG2CODEDEV`
Create this environment in repo **Settings → Environments** and add the following secrets:

| Secret | Value |
|---|---|
| `AZURE_TENANT_ID` | Your Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID |
| `AZURE_CLIENT_ID` | Deployment service principal client ID |
| `AZURE_CLIENT_SECRET` | Deployment service principal client secret |

### Azure Service Principal Permissions
The deployment SP (`AZURE_CLIENT_ID`) requires the following before running Terraform:

- **Azure RBAC**: `Contributor` + `User Access Administrator` on the target subscription (or resource group scope)
- **Entra ID** (if `layer_service_principal_mode = create`): `Application.ReadWrite.All` or `Directory.ReadWrite.All`
  - If restricted by tenant policy, set `layer_service_principal_mode = existing` and populate `existing_layer_sp_client_id` / `existing_layer_sp_object_id` (add as GitHub secrets and pass via `TF_VAR_*`)
- **Key Vault**: `Key Vault Secrets Officer` on the provisioned Key Vault (required to create the AKV-backed secret scope)

## After Infrastructure Deployment

### Populate Azure Key Vault Secrets
Once `deploy-infrastructure.yml` completes, add the following secrets to the Key Vault (name shown in Terraform output `key_vault_name`):

| Key Vault Secret Name | Description |
|---|---|
| `jdbc-host` | JDBC source database hostname |
| `jdbc-database` | JDBC source database name |
| `jdbc-user` | JDBC source database username |
| `jdbc-password` | JDBC source database password |

Use the CLI or Azure Portal – never hardcode these values:
```bash
az keyvault secret set --vault-name <kv-name> --name jdbc-host     --value "<hostname>"
az keyvault secret set --vault-name <kv-name> --name jdbc-database  --value "<db-name>"
az keyvault secret set --vault-name <kv-name> --name jdbc-user      --value "<username>"
az keyvault secret set --vault-name <kv-name> --name jdbc-password  --value "<password>"
```

### Run `deploy-dab.yml`
After infrastructure is deployed and Key Vault secrets are populated, trigger `deploy-dab.yml` to register the Lakeflow jobs in the workspace.

## State Management (Known Limitation)

Terraform uses **local, ephemeral state** in GitHub Actions. Each workflow run starts with empty state.

**If you rerun `deploy-infrastructure.yml` after a previous partial or full run:**
1. Delete the resource group: `az group delete --name rg-blg-dev-uks --yes --no-wait`
2. Wait for deletion, then re-trigger the workflow.

**For persistent state (recommended for production):**
- Create an Azure Storage account and blob container for the backend.
- Add a `backend "azurerm"` block to `infra/terraform/versions.tf`.
- Update `deploy-infrastructure.yml` to pass backend config via `-backend-config`.

## Post-Deployment Hardening (Optional)

- Disable storage shared key access once all access is via managed identity: set `storage_shared_key_enabled = false` in the workflow inputs and rerun.
- Enable Azure Key Vault diagnostic logs for secret-access auditing.
- Enable Databricks system tables for per-layer job cost and reliability monitoring.
- Review and tighten Unity Catalog grants as data access patterns solidify.

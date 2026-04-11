# ── Azure Resource Manager provider ──────────────────────────────────────────
# Authentication: set via env vars or az login
#   ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET
provider "azurerm" {
  subscription_id = var.azure_subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# ── Azure Active Directory provider ──────────────────────────────────────────
provider "azuread" {
  tenant_id = var.azure_tenant_id
}

# ── Databricks account-level provider ────────────────────────────────────────
# Used solely for Unity Catalog metastore assignment.
# Authentication: set DATABRICKS_ACCOUNT_ID, DATABRICKS_CLIENT_ID,
#                 DATABRICKS_CLIENT_SECRET as environment variables, or use
#                 a service principal with account-admin role.
provider "databricks" {
  alias      = "account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id
}

# ── Databricks workspace-level provider ──────────────────────────────────────
# Initialised after the workspace resource is created; Terraform resolves this
# lazily on the second pass.
# Authentication: set DATABRICKS_TOKEN (workspace PAT) or use SP OAuth
#   (DATABRICKS_CLIENT_ID + DATABRICKS_CLIENT_SECRET).
provider "databricks" {
  alias = "workspace"
  host  = azurerm_databricks_workspace.main.workspace_url
}

provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted
    }
  }

  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

provider "azuread" {
  tenant_id = var.azure_tenant_id
}

# Databricks provider authenticated via the same Azure service principal.
# Used solely to provision Unity Catalog catalogs after the workspace exists.
provider "databricks" {
  host                = "https://${azurerm_databricks_workspace.this.workspace_url}"
  azure_tenant_id     = var.azure_tenant_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
}

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

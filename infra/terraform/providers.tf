provider "azurerm" {
  features {
    key_vault {
      # Keep recovery mode configurable so ephemeral reruns can recover or create fresh vaults deterministically.
      recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted
    }
  }

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

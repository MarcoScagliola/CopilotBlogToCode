provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = var.key_vault_purge_soft_deleted
      recover_soft_deleted_keys          = var.key_vault_recover_soft_deleted
    }
  }

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "random" {}

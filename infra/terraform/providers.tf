provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted
      purge_soft_delete_on_destroy    = false
    }
  }

  subscription_id = var.subscription_id
}

provider "azuread" {}

provider "time" {}

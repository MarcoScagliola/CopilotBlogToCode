provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted
    }
  }
}

provider "azuread" {}
provider "random" {}

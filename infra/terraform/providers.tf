provider "azurerm" {
  features {
    key_vault {
      # Retain soft-deleted vaults during development cycles.
      # The deploy workflow handles recovery; do not purge on destroy by default.
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

provider "random" {}

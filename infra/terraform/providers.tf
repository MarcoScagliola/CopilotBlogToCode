provider "azurerm" {
  features {
    key_vault {
      # Retain soft-deleted vaults during development cycles.
      # The deploy workflow handles recovery; do not purge on destroy by default.
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted
    }
    resource_group {
      # Allow destroy even when the resource group still contains resources.
      prevent_deletion_if_contains_resources = false
    }
  }

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

provider "azuread" {
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

provider "random" {}

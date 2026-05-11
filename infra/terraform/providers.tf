provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  features {
    key_vault {
      recover_soft_deleted_key_vaults    = var.key_vault_recover_soft_deleted
      purge_soft_delete_on_destroy       = false
      purge_soft_deleted_keys_on_destroy = false
      purge_soft_deleted_secrets_on_destroy = false
      purge_soft_deleted_certificates_on_destroy = false
    }
  }
}

provider "azuread" {
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

provider "random" {}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy            = false
      recover_soft_deleted_key_vaults         = var.key_vault_recover_soft_deleted
      purge_soft_deleted_keys_on_destroy      = false
      purge_soft_deleted_secrets_on_destroy   = false
      purge_soft_deleted_certificates_on_destroy = false
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

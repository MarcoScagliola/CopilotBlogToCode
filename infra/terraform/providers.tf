terraform {
  # Un-comment for cloud backend (e.g., Azure Storage Account)
  # backend "azurerm" {
  #   resource_group_name  = "my-rg"
  #   storage_account_name = "mystg"
  #   container_name       = "tfstate"
  #   key                  = "blg-dev.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
  }

  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}

provider "azuread" {
  tenant_id = var.azure_tenant_id
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  auth_type  = "oauth_service_principal"
  client_id  = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

provider "databricks" {
  alias                        = "workspace"
  host                         = databricks_mws_workspaces.blg.workspace_url
  account_id                   = var.databricks_account_id
  auth_type                    = "oauth_service_principal"
  client_id                    = var.databricks_client_id
  client_secret                = var.databricks_client_secret
  skip_getting_workspace_id    = true
  skip_terraform_state_mocking = true
  skip_default_client_data     = true
}

data "azurerm_client_config" "current" {}

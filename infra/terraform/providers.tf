provider "azurerm" {
  features {}
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}

provider "azuread" {
  tenant_id = var.azure_tenant_id
}

provider "databricks" {
  alias      = "workspace"
  host       = azurerm_databricks_workspace.this.workspace_url
  auth_type  = "pat"
  token      = var.databricks_workspace_pat_token
}

provider "databricks" {
  alias         = "account"
  host          = "https://accounts.azuredatabricks.net"
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

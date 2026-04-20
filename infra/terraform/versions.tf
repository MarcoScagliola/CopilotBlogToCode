terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.2.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.40.0"
    }
  }
}

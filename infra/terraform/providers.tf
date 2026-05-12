provider "azurerm" {
  features {
    key_vault {
      # Avoid accidental hard purge of soft-deleted vaults during dev iteration.
      # Set to false if you want purge-on-destroy behaviour in ephemeral environments.
      purge_soft_delete_on_destroy = false

      # Driven by a variable so the deploy workflow can flip recovery mode without
      # editing provider config. Required for the Key Vault soft-delete recovery state
      # machine in deploy-infrastructure.yml.
      recover_soft_deleted_key_vaults = var.key_vault_recover_soft_deleted
    }
  }
}

# Empty azuread provider block — credentials come from ARM_* environment variables
# set by the deploy workflow. No credentials are hardcoded here.
provider "azuread" {}

# Empty random provider block — used for unique suffixes if needed in the future.
provider "random" {}

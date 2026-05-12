# ---------------------------------------------------------------------------
# Identity — deployment principal
# ---------------------------------------------------------------------------

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID. Sourced from GitHub Secrets (AZURE_TENANT_ID)."
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID. Sourced from GitHub Secrets (AZURE_SUBSCRIPTION_ID)."
  sensitive   = true
}

variable "client_id" {
  type        = string
  description = "Deployment service principal application (client) ID. Sourced from GitHub Secrets (AZURE_CLIENT_ID)."
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "Deployment service principal client secret. Sourced from GitHub Secrets (AZURE_CLIENT_SECRET)."
  sensitive   = true
}

variable "sp_object_id" {
  type        = string
  description = "Deployment service principal Enterprise Application object ID. Used for RBAC assignments. Sourced from GitHub Secrets (AZURE_SP_OBJECT_ID)."
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Workload identification
# ---------------------------------------------------------------------------

variable "workload" {
  type        = string
  description = "Short workload identifier used in all resource names (e.g. 'blg')."
  default     = "blg"

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must be a non-empty string."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, prd)."
  default     = "dev"

  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "environment must be 'dev' or 'prd'."
  }
}

variable "azure_region" {
  type        = string
  description = "Azure region for all resources (e.g. 'uksouth')."
  default     = "uksouth"
}

# ---------------------------------------------------------------------------
# Layer identity mode
# ---------------------------------------------------------------------------

variable "layer_sp_mode" {
  type        = string
  description = "How per-layer service principals are sourced. 'create' creates new Entra ID app registrations; 'existing' reuses identities supplied via existing_layer_sp_* variables."
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  type        = string
  description = "Client ID of the pre-existing layer service principal. Required when layer_sp_mode='existing'."
  default     = ""
  sensitive   = true
}

variable "existing_layer_sp_object_id" {
  type        = string
  description = "Enterprise Application object ID of the pre-existing layer service principal. Required when layer_sp_mode='existing'."
  default     = ""
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Key Vault recovery
# ---------------------------------------------------------------------------

variable "key_vault_recover_soft_deleted" {
  type        = bool
  description = "When true, the azurerm provider will attempt to recover a soft-deleted Key Vault with the same name rather than fail. Set by the deploy workflow's recovery-state machine."
  default     = true
}

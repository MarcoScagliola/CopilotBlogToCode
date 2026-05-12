# ── Identity variables ────────────────────────────────────────────────────────
# These come from GitHub Secrets/Variables via TF_VAR_* in the deploy workflow.
# Names match the deploy-infrastructure workflow contract exactly (no azure_ prefix).

variable "tenant_id" {
  description = "Azure tenant ID for the deployment."
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure subscription ID for the deployment."
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Application (client) ID of the deployment service principal."
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Client secret of the deployment service principal."
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Enterprise Application (service principal) object ID of the deployment principal. Used for Key Vault access policy."
  type        = string
  sensitive   = true
}

# ── Layer service principal mode ──────────────────────────────────────────────

variable "layer_sp_mode" {
  description = "How per-layer service principals are sourced. 'create' provisions new Entra ID app registrations and service principals. 'existing' reuses the identifiers supplied in existing_layer_sp_* variables."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be 'create' or 'existing'."
  }
}

# ── Existing-mode principal identifiers (only required when layer_sp_mode=existing) ──

variable "existing_layer_sp_client_id" {
  description = "Application (client) ID of the pre-existing layer service principal. Required when layer_sp_mode=existing."
  type        = string
  sensitive   = true
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Enterprise Application object ID of the pre-existing layer service principal. Required when layer_sp_mode=existing."
  type        = string
  sensitive   = true
  default     = ""
}

# ── Workload coordinates ──────────────────────────────────────────────────────

variable "workload" {
  description = "Short workload identifier used in resource naming (e.g. 'blg')."
  type        = string
  default     = "blg"
}

variable "environment" {
  description = "Deployment environment (e.g. 'dev', 'prd')."
  type        = string
  default     = "dev"
}

variable "azure_region" {
  description = "Azure region for all resources (e.g. 'uksouth')."
  type        = string
  default     = "uksouth"
}

# ── Key Vault recovery ────────────────────────────────────────────────────────

variable "key_vault_recover_soft_deleted" {
  description = "Set to true to recover a soft-deleted Key Vault matching the target name. Set to false to skip recovery and create fresh. Driven per-run by the deploy workflow's key_vault_recovery_mode logic."
  type        = bool
  default     = true
}

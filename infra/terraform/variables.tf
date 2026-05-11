variable "workload" {
  description = "Short workload identifier used in naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "azure_region" {
  description = "Azure region for deployment, for example uksouth."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "client_id" {
  description = "Deployment principal client ID."
  type        = string
}

variable "client_secret" {
  description = "Deployment principal client secret."
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Deployment principal service principal object ID."
  type        = string
}

variable "layer_sp_mode" {
  description = "How layer principals are sourced: create or existing."
  type        = string

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either create or existing."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Existing layer principal client ID used when layer_sp_mode=existing."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Existing layer principal object ID used when layer_sp_mode=existing."
  type        = string
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether to recover soft-deleted Key Vault resources during apply."
  type        = bool
  default     = true
}

variable "enable_storage_shared_key" {
  description = "Keep storage shared key enabled for provider compatibility during initial provisioning."
  type        = bool
  default     = true
}

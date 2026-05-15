variable "tenant_id" {
  type        = string
  description = "Azure tenant ID used for provider authentication."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID used for provider authentication and resource IDs."
}

variable "client_id" {
  type        = string
  description = "Deployment service principal client ID."
}

variable "client_secret" {
  type        = string
  description = "Deployment service principal client secret."
  sensitive   = true
}

variable "sp_object_id" {
  type        = string
  description = "Deployment service principal object ID from Enterprise Applications."
}

variable "workload" {
  type        = string
  description = "Short workload code used in resource naming."
}

variable "environment" {
  type        = string
  description = "Environment code used in resource naming and tagging."
}

variable "azure_region" {
  type        = string
  description = "Azure region where resources are created."
}

variable "layer_sp_mode" {
  type        = string
  description = "Identity mode. Use create for generated identities or existing for pre-created principals."
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be create or existing."
  }
}

variable "existing_layer_sp_client_id" {
  type        = string
  description = "Existing layer principal client ID when layer_sp_mode is existing."
  default     = ""
}

variable "existing_layer_sp_object_id" {
  type        = string
  description = "Existing layer principal object ID when layer_sp_mode is existing."
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  type        = bool
  description = "Whether provider should attempt Key Vault soft-delete recovery."
  default     = true
}

variable "enable_shared_key" {
  type        = bool
  description = "Compatibility toggle for storage account shared key access."
  default     = true
}

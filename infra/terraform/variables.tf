variable "tenant_id" {
  type        = string
  description = "Azure tenant ID."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
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
  description = "Deployment service principal object ID."
}

variable "workload" {
  type        = string
  description = "Workload short code."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "azure_region" {
  type        = string
  description = "Azure region for deployment."
}

variable "layer_sp_mode" {
  type        = string
  description = "Layer service principal mode: create or existing."

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  type        = string
  description = "Existing layer service principal client ID (used in existing mode)."
  default     = ""
}

variable "existing_layer_sp_object_id" {
  type        = string
  description = "Existing layer service principal object ID (used in existing mode)."
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  type        = bool
  description = "Whether to recover soft deleted key vaults."
  default     = true
}

variable "tenant_id" {
  description = "Azure tenant ID used by Terraform provider authentication."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID used by Terraform provider authentication."
  type        = string
}

variable "client_id" {
  description = "Deployment service principal application (client) ID."
  type        = string
}

variable "client_secret" {
  description = "Deployment service principal client secret."
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Deployment service principal object ID from Enterprise Applications."
  type        = string
}

variable "workload" {
  description = "Workload short code used in naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment code (for example dev, tst, prd)."
  type        = string
}

variable "azure_region" {
  description = "Azure region used for resource deployment."
  type        = string
}

variable "layer_sp_mode" {
  description = "Layer principal strategy: create new per-layer principals, or reuse existing IDs."
  type        = string

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either create or existing."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Existing layer principal application (client) ID used when layer_sp_mode=existing."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Existing layer principal object ID used when layer_sp_mode=existing."
  type        = string
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  description = "Controls AzureRM provider soft-deleted Key Vault recovery behavior."
  type        = bool
  default     = true
}

variable "storage_account_replication_type" {
  description = "Replication type for layer storage accounts."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], upper(var.storage_account_replication_type))
    error_message = "storage_account_replication_type must be one of LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  }
}

variable "enable_shared_key" {
  description = "Provider-compatible default for storage auth; set false as post-deploy hardening."
  type        = bool
  default     = true
}

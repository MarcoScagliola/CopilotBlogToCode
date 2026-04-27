variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Service principal client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Service principal client secret"
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Service principal object ID (Enterprise Application)"
  type        = string
  sensitive   = true
}

variable "workload" {
  description = "Workload name used in resource naming"
  type        = string
  default     = "etl"

  validation {
    condition     = length(var.workload) <= 8 && can(regex("^[a-z]+$", var.workload))
    error_message = "Workload must be alphanumeric and at most 8 characters."
  }
}

variable "environment" {
  description = "Environment name used in resource naming"
  type        = string
  default     = "dev"

  validation {
    condition     = length(var.environment) <= 8 && can(regex("^[a-z]+$", var.environment))
    error_message = "Environment must be alphanumeric and at most 8 characters."
  }
}

variable "azure_region" {
  description = "Azure region for deployment"
  type        = string
  default     = "uksouth"
}

variable "layer_sp_mode" {
  description = "How layer service principals are sourced: 'create' (new) or 'existing' (pre-created)"
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID of existing layer service principal (required when layer_sp_mode=existing)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "existing_layer_sp_object_id" {
  description = "Object ID of existing layer service principal (required when layer_sp_mode=existing)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "key_vault_recover_soft_deleted" {
  description = "Recover soft-deleted Key Vault if it exists"
  type        = bool
  default     = true
}

variable "key_vault_purge_soft_deleted" {
  description = "Purge soft-deleted Key Vault on destroy"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key on storage accounts (required for initial provisioning)"
  type        = bool
  default     = true
}

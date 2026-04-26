variable "workload" {
  description = "Workload short name used for resource naming."
  type        = string
  default     = "etl"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "azure_region" {
  description = "Azure region for deployment."
  type        = string
  default     = "uksouth"
}

variable "azure_tenant_id" {
  description = "Azure tenant ID used by providers."
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure subscription ID used by providers."
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Client ID for deployment principal."
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Client secret for deployment principal."
  type        = string
  sensitive   = true
}

variable "azure_sp_object_id" {
  description = "Enterprise Application object ID for deployment principal."
  type        = string
}

variable "layer_sp_mode" {
  description = "Whether to create layer principals or reuse existing ones."
  type        = string
  default     = "existing"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID for existing layer principal when layer_sp_mode=existing."
  type        = string
  default     = ""

  validation {
    condition     = var.layer_sp_mode != "existing" || trimspace(var.existing_layer_sp_client_id) != ""
    error_message = "When layer_sp_mode='existing', existing_layer_sp_client_id must be non-empty."
  }
}

variable "existing_layer_sp_object_id" {
  description = "Object ID for existing layer principal when layer_sp_mode=existing."
  type        = string
  default     = ""

  validation {
    condition     = var.layer_sp_mode != "existing" || trimspace(var.existing_layer_sp_object_id) != ""
    error_message = "When layer_sp_mode='existing', existing_layer_sp_object_id must be non-empty."
  }
}

variable "key_vault_recover_soft_deleted" {
  description = "Recover soft-deleted key vaults during create/update."
  type        = bool
  default     = true
}

variable "key_vault_enable_purge_protection" {
  description = "Enable purge protection for Key Vault."
  type        = bool
  default     = false
}

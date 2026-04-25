variable "tenant_id" {
  type        = string
  description = "Azure tenant ID used by providers."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for deployment."
}

variable "workload" {
  type        = string
  description = "Workload short code used for naming."
}

variable "environment" {
  type        = string
  description = "Deployment environment code (dev/test/prd)."
}

variable "azure_region" {
  type        = string
  description = "Azure region for all resources."
}

variable "deployment_sp_object_id" {
  type        = string
  description = "Object ID of deployment service principal used for RBAC assignments."
}

variable "layer_sp_mode" {
  type        = string
  description = "Layer principal provisioning mode: create new principals or reuse existing."
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  type        = string
  description = "Existing layer principal client ID (required when layer_sp_mode=existing)."
  default     = ""

  validation {
    condition     = var.layer_sp_mode != "existing" || trimspace(var.existing_layer_sp_client_id) != ""
    error_message = "existing_layer_sp_client_id is required when layer_sp_mode is 'existing'."
  }
}

variable "existing_layer_sp_object_id" {
  type        = string
  description = "Existing layer principal object ID (required when layer_sp_mode=existing)."
  default     = ""

  validation {
    condition     = var.layer_sp_mode != "existing" || trimspace(var.existing_layer_sp_object_id) != ""
    error_message = "existing_layer_sp_object_id is required when layer_sp_mode is 'existing'."
  }
}

variable "key_vault_recover_soft_deleted" {
  type        = bool
  description = "Whether provider should recover a soft-deleted Key Vault during apply."
  default     = true
}

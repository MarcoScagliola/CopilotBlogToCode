variable "tenant_id" {
  type        = string
  description = "Azure tenant id"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription id"
}

variable "client_id" {
  type        = string
  description = "Deployment service principal client id"
}

variable "client_secret" {
  type        = string
  description = "Deployment service principal client secret"
  sensitive   = true
}

variable "sp_object_id" {
  type        = string
  description = "Deployment service principal object id"
}

variable "workload" {
  type        = string
  description = "Short workload name"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev/prd)"
}

variable "azure_region" {
  type        = string
  description = "Azure region (for example uksouth)"
}

variable "layer_sp_mode" {
  type        = string
  description = "Whether layer principals are created or reused"
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be one of: create, existing"
  }
}

variable "existing_layer_sp_client_id" {
  type        = string
  description = "Existing layer principal client id used when layer_sp_mode=existing"
  default     = ""
}

variable "existing_layer_sp_object_id" {
  type        = string
  description = "Existing layer principal object id used when layer_sp_mode=existing"
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  type        = bool
  description = "Controls AzureRM key vault soft-delete recovery behavior"
  default     = true
}

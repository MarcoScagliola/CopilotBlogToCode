variable "tenant_id" {
  description = "Azure tenant ID used for provider authentication"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID used for provider authentication"
  type        = string
}

variable "client_id" {
  description = "Deployment service principal client ID"
  type        = string
}

variable "client_secret" {
  description = "Deployment service principal client secret"
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Deployment service principal object ID (Enterprise Application object ID)"
  type        = string
}

variable "workload" {
  description = "Short workload identifier used in naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "azure_region" {
  description = "Azure region"
  type        = string
}

variable "key_vault_recover_soft_deleted" {
  description = "Controls key vault soft-delete recovery behavior in provider features"
  type        = bool
  default     = true
}

variable "layer_sp_mode" {
  description = "Service principal sourcing model for layer runtime identity"
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either 'create' or 'existing'."
  }
}

variable "shared_access_key_enabled" {
  description = "Whether account key authentication remains enabled on storage accounts"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Optional tags applied to all resources"
  type        = map(string)
  default     = {}
}

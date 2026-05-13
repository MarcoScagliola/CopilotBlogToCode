variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "client_id" {
  description = "Deployment service principal application (client) ID"
  type        = string
}

variable "client_secret" {
  description = "Deployment service principal client secret"
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Deployment service principal object ID from Enterprise Applications"
  type        = string
}

variable "workload" {
  description = "Short workload code"
  type        = string
  default     = "blg"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "layer_sp_mode" {
  description = "How to source layer service principals"
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be one of: create, existing."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Existing shared layer service principal application (client) ID"
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Existing shared layer service principal object ID"
  type        = string
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether Key Vault soft-deleted vaults should be recovered"
  type        = bool
  default     = true
}

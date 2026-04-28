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
  description = "Short workload code"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "azure_region" {
  type        = string
  description = "Azure region for deployment"
}

variable "layer_sp_mode" {
  type        = string
  description = "Whether to create layer principals or use an existing one"
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be one of: create, existing"
  }
}

variable "existing_layer_sp_client_id" {
  type        = string
  description = "Existing layer principal client id for existing mode"
  default     = ""
}

variable "existing_layer_sp_object_id" {
  type        = string
  description = "Existing layer principal object id for existing mode"
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  type        = bool
  description = "Controls provider key vault soft-delete recovery behavior"
  default     = true
}

variable "tenant_id" {
  description = "Azure tenant ID for provider authentication."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID for deployment."
  type        = string
}

variable "client_id" {
  description = "Deployment service principal client ID."
  type        = string
}

variable "client_secret" {
  description = "Deployment service principal client secret."
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Deployment service principal object ID (Enterprise App object ID)."
  type        = string
}

variable "workload" {
  description = "Workload short name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "azure_region" {
  description = "Azure region for resource deployment."
  type        = string
}

variable "layer_sp_mode" {
  description = "How layer identities are sourced: create or existing."
  type        = string

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Existing layer service principal client ID when layer_sp_mode=existing."
  type        = string
}

variable "existing_layer_sp_object_id" {
  description = "Existing layer service principal object ID when layer_sp_mode=existing."
  type        = string
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether provider recovers soft-deleted key vaults."
  type        = bool
  default     = true
}

variable "databricks_workspace_sku" {
  description = "Databricks workspace SKU."
  type        = string
  default     = "premium"
}
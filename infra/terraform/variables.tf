variable "tenant_id" {
  description = "Azure tenant ID used by Terraform authentication."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID used by Terraform authentication."
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
  description = "Deployment service principal object ID from Enterprise Applications."
  type        = string
}

variable "workload" {
  description = "Short workload identifier used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
}

variable "azure_region" {
  description = "Azure region where resources are deployed."
  type        = string
}

variable "layer_sp_mode" {
  description = "How layer principals are sourced (create or existing)."
  type        = string

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID to use when layer_sp_mode is existing."
  type        = string
}

variable "existing_layer_sp_object_id" {
  description = "Object ID to use when layer_sp_mode is existing."
  type        = string
}

variable "key_vault_recover_soft_deleted" {
  description = "Controls AzureRM provider behavior for Key Vault soft-delete recovery."
  type        = bool
  default     = true
}

variable "enable_shared_key" {
  description = "Keep true for provider compatibility during provisioning; disable later as a hardening step."
  type        = bool
  default     = true
}

variable "bronze_catalog_name" {
  description = "Bronze catalog name passed to DAB deploy bridge."
  type        = string
  default     = "bronze"
}

variable "silver_catalog_name" {
  description = "Silver catalog name passed to DAB deploy bridge."
  type        = string
  default     = "silver"
}

variable "gold_catalog_name" {
  description = "Gold catalog name passed to DAB deploy bridge."
  type        = string
  default     = "gold"
}

variable "secret_scope_name" {
  description = "Databricks secret scope name backed by Azure Key Vault."
  type        = string
  default     = "kv-dev-scope"
}

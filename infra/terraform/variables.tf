variable "tenant_id" {
  description = "Azure tenant ID for deployment authentication."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID for deployment authentication."
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
  description = "Short workload code used in naming."
  type        = string
}

variable "environment" {
  description = "Environment suffix used in naming."
  type        = string
}

variable "azure_region" {
  description = "Azure region used for resources."
  type        = string
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether provider recovery behavior for soft-deleted Key Vault should be enabled."
  type        = bool
  default     = true
}

variable "layer_sp_mode" {
  description = "How layer principals are sourced: create or existing."
  type        = string
  default     = "existing"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be one of: create, existing."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Existing layer principal client ID used when layer_sp_mode=existing."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Existing layer principal object ID used when layer_sp_mode=existing."
  type        = string
  default     = ""
}

variable "bronze_catalog" {
  description = "Unity Catalog catalog for the bronze layer."
  type        = string
  default     = "bronze"
}

variable "silver_catalog" {
  description = "Unity Catalog catalog for the silver layer."
  type        = string
  default     = "silver"
}

variable "gold_catalog" {
  description = "Unity Catalog catalog for the gold layer."
  type        = string
  default     = "gold"
}

variable "bronze_schema" {
  description = "Unity Catalog schema for the bronze layer."
  type        = string
  default     = "raw"
}

variable "silver_schema" {
  description = "Unity Catalog schema for the silver layer."
  type        = string
  default     = "refined"
}

variable "gold_schema" {
  description = "Unity Catalog schema for the gold layer."
  type        = string
  default     = "curated"
}

variable "secret_scope" {
  description = "Databricks secret scope name used by jobs."
  type        = string
  default     = "kv-dev-scope"
}

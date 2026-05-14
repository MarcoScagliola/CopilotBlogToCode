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
  description = "Deployment service principal object ID from Enterprise Applications."
  type        = string
}

variable "workload" {
  description = "Workload short name used in canonical resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used in canonical resource naming."
  type        = string
}

variable "azure_region" {
  description = "Azure region for the deployment."
  type        = string
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether the AzureRM provider should recover a soft-deleted Key Vault during apply."
  type        = bool
  default     = true
}

variable "databricks_workspace_sku" {
  description = "Azure Databricks workspace SKU."
  type        = string
  default     = "premium"
}
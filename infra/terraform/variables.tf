variable "tenant_id" {
  description = "Azure tenant ID used by Terraform and RBAC resources."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID used for deployment."
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
  description = "Enterprise application object ID for deployment principal."
  type        = string
}

variable "workload" {
  description = "Short workload identifier used in resource names."
  type        = string
}

variable "environment" {
  description = "Environment identifier such as dev or prd."
  type        = string
}

variable "azure_region" {
  description = "Azure region for deployment."
  type        = string
}

variable "key_vault_recover_soft_deleted" {
  description = "Controls Key Vault soft-delete recovery behavior in provider features."
  type        = bool
  default     = true
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID for provider authentication."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for provider authentication."
}

variable "client_id" {
  type        = string
  description = "Deployment principal client ID."
}

variable "client_secret" {
  type        = string
  description = "Deployment principal client secret."
  sensitive   = true
}

variable "sp_object_id" {
  type        = string
  description = "Deployment principal service principal object ID from Enterprise Applications."
}

variable "workload" {
  type        = string
  description = "Workload short code used in naming."

  validation {
    condition     = length(trimspace(var.workload)) >= 2 && length(trimspace(var.workload)) <= 12
    error_message = "workload must be between 2 and 12 characters."
  }
}

variable "environment" {
  type        = string
  description = "Environment code used in naming."

  validation {
    condition     = contains(["dev", "tst", "prd"], var.environment)
    error_message = "environment must be one of dev, tst, prd."
  }
}

variable "azure_region" {
  type        = string
  description = "Azure region name."
}

variable "key_vault_recover_soft_deleted" {
  type        = bool
  description = "Controls provider-level Key Vault soft-delete recovery behavior."
  default     = true
}

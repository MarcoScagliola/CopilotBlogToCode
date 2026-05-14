variable "tenant_id" {
  description = "Microsoft Entra tenant ID used for provider authentication."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.tenant_id)) > 0
    error_message = "tenant_id must not be empty."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID used for provider authentication and resource placement."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.subscription_id)) > 0
    error_message = "subscription_id must not be empty."
  }
}

variable "client_id" {
  description = "Application (client) ID of the deployment service principal."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.client_id)) > 0
    error_message = "client_id must not be empty."
  }
}

variable "client_secret" {
  description = "Client secret of the deployment service principal."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.client_secret)) > 0
    error_message = "client_secret must not be empty."
  }
}

variable "sp_object_id" {
  description = "Enterprise application object ID of the deployment service principal."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.sp_object_id)) > 0
    error_message = "sp_object_id must not be empty."
  }
}

variable "workload" {
  description = "Workload short name used in canonical resource naming."
  type        = string

  validation {
    condition     = length(trimspace(var.workload)) > 0
    error_message = "workload must not be empty."
  }
}

variable "environment" {
  description = "Deployment environment used in canonical resource naming."
  type        = string

  validation {
    condition     = contains(["dev", "prd"], lower(trimspace(var.environment)))
    error_message = "environment must be one of: dev, prd."
  }
}

variable "azure_region" {
  description = "Azure region used for all Azure resources."
  type        = string

  validation {
    condition     = contains(["eastus", "eastus2", "westus2", "westeurope", "northeurope", "uksouth", "ukwest"], lower(trimspace(var.azure_region)))
    error_message = "azure_region must be one of: eastus, eastus2, westus2, westeurope, northeurope, uksouth, ukwest."
  }
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether AzureRM should recover soft-deleted Key Vaults when the target name already exists in soft delete."
  type        = bool
  default     = true
}
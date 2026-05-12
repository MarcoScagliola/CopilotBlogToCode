variable "tenant_id" {
  description = "Azure tenant ID for provider authentication."
  type        = string
  sensitive   = true

  validation {
    condition     = trimspace(var.tenant_id) != ""
    error_message = "tenant_id must not be empty."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID for provider authentication."
  type        = string
  sensitive   = true

  validation {
    condition     = trimspace(var.subscription_id) != ""
    error_message = "subscription_id must not be empty."
  }
}

variable "client_id" {
  description = "Azure service principal client ID used by Terraform."
  type        = string
  sensitive   = true

  validation {
    condition     = trimspace(var.client_id) != ""
    error_message = "client_id must not be empty."
  }
}

variable "client_secret" {
  description = "Azure service principal client secret used by Terraform."
  type        = string
  sensitive   = true

  validation {
    condition     = trimspace(var.client_secret) != ""
    error_message = "client_secret must not be empty."
  }
}

variable "sp_object_id" {
  description = "Object ID of deployment service principal (Enterprise Application) for role assignment and Key Vault policy."
  type        = string
  sensitive   = true

  validation {
    condition     = trimspace(var.sp_object_id) != ""
    error_message = "sp_object_id must not be empty."
  }
}

variable "workload" {
  description = "Short workload identifier used in naming."
  type        = string
  default     = "blg"

  validation {
    condition     = trimspace(var.workload) != ""
    error_message = "workload must not be empty."
  }
}

variable "environment" {
  description = "Deployment environment code."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "environment must be one of: dev, prd."
  }
}

variable "azure_region" {
  description = "Azure region for resource deployment."
  type        = string
  default     = "uksouth"

  validation {
    condition     = trimspace(var.azure_region) != ""
    error_message = "azure_region must not be empty."
  }
}

variable "layer_sp_mode" {
  description = "Controls whether layer-specific service principals are created or reused from existing values."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be one of: create, existing."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Existing service principal client ID used when layer_sp_mode=existing."
  type        = string
  default     = ""
  sensitive   = true
}

variable "existing_layer_sp_object_id" {
  description = "Existing service principal object ID used when layer_sp_mode=existing."
  type        = string
  default     = ""
  sensitive   = true
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether to recover soft-deleted Key Vaults during deployment."
  type        = bool
  default     = true
}

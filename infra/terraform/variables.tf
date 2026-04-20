variable "workload" {
  description = "Short workload identifier used in resource names."
  type        = string
  default     = "blg"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "tst", "prd"], var.environment)
    error_message = "environment must be one of: dev, tst, prd."
  }
}

variable "azure_region" {
  description = "Azure region where resources are deployed."
  type        = string
  default     = "eastus2"
}

variable "azure_tenant_id" {
  description = "Azure tenant ID for provider authentication."
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID for provider authentication."
  type        = string
}

variable "azure_client_id" {
  description = "Deployment service principal client ID (application ID)."
  type        = string
}

variable "azure_sp_object_id" {
  description = "Deployment service principal object ID (Enterprise Applications object ID)."
  type        = string
}

variable "layer_sp_mode" {
  description = "Layer principal mode: create new principals or reuse existing ones."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID for an existing reusable layer principal (required in existing mode)."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Object ID for an existing reusable layer principal (required in existing mode)."
  type        = string
  default     = ""
}

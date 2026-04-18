variable "workload" {
  description = "Short workload name used for resource naming."
  type        = string
  default     = "blg"
}

variable "environment" {
  description = "Environment short name."
  type        = string
  default     = "dev"
}

variable "azure_region" {
  description = "Azure region for deployment."
  type        = string
  default     = "uksouth"
}

variable "azure_tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "azure_client_id" {
  description = "Deployment service principal client ID."
  type        = string
}

variable "azure_client_secret" {
  description = "Deployment service principal secret."
  type        = string
  sensitive   = true
}

variable "azure_sp_object_id" {
  description = "Deployment service principal object ID (Enterprise Application object ID, used for RBAC)."
  type        = string
}

variable "layer_service_principal_mode" {
  description = "Whether to create dedicated layer principals ('create') or reuse an existing one ('existing')."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_service_principal_mode)
    error_message = "layer_service_principal_mode must be 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID to reuse when layer_service_principal_mode is 'existing'."
  type        = string
  default     = ""

  validation {
    condition = (
      var.layer_service_principal_mode != "existing" ||
      length(trimspace(var.existing_layer_sp_client_id)) > 0
    )
    error_message = "existing_layer_sp_client_id must be provided when layer_service_principal_mode is 'existing'."
  }
}

variable "existing_layer_sp_object_id" {
  description = "Object ID to reuse when layer_service_principal_mode is 'existing'. Must be a Service Principal (Enterprise Application) object ID."
  type        = string
  default     = ""

  validation {
    condition = (
      var.layer_service_principal_mode != "existing" ||
      length(trimspace(var.existing_layer_sp_object_id)) > 0
    )
    error_message = "existing_layer_sp_object_id must be provided when layer_service_principal_mode is 'existing'."
  }
}

variable "azure_tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Deployment service principal client ID."
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Deployment service principal client secret."
  type        = string
  sensitive   = true
}

variable "azure_sp_object_id" {
  description = "Deployment service principal object ID for role assignments."
  type        = string
}

variable "workload" {
  description = "Short workload name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/prd)."
  type        = string
}

variable "azure_region" {
  description = "Azure region for resources."
  type        = string
}

variable "layer_service_principal_mode" {
  description = "create = create per-layer Entra app/SP, existing = reuse pre-created SP."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_service_principal_mode)
    error_message = "layer_service_principal_mode must be create or existing."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Existing layer runner SP client ID (required when mode=existing)."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Existing layer runner SP object ID (required when mode=existing)."
  type        = string
  default     = ""
}

variable "storage_shared_key_enabled" {
  description = "Keep true by default for AzureRM provisioning compatibility; harden post-deploy if needed."
  type        = bool
  default     = true
}

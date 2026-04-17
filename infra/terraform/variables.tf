variable "workload" {
  description = "Short workload identifier used for naming."
  type        = string
  default     = "blg"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "azure_region" {
  description = "Azure region for the deployment."
  type        = string
  default     = "uksouth"
}

variable "azure_tenant_id" {
  description = "Azure tenant ID injected by the deployment workflow."
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure subscription ID injected by the deployment workflow."
  type        = string
  sensitive   = true
}

variable "layer_service_principal_mode" {
  description = "How layer service principals are sourced: 'create' creates per-layer Entra apps, 'existing' reuses one existing service principal for all layers."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_service_principal_mode)
    error_message = "layer_service_principal_mode must be either 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID (application ID) of an existing service principal to reuse when layer_service_principal_mode is 'existing'."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Object ID of an existing service principal to reuse when layer_service_principal_mode is 'existing'."
  type        = string
  default     = ""
}

variable "databricks_sku" {
  description = "Azure Databricks workspace SKU."
  type        = string
  default     = "premium"
}

variable "secret_scope_name" {
  description = "Optional override for the AKV-backed Databricks secret scope name."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Optional tags applied to Azure resources."
  type        = map(string)
  default     = {}
}

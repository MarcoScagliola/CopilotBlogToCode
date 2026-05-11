variable "workload" {
  description = "Short workload identifier (for naming)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (for naming and tags)."
  type        = string
}

variable "azure_region" {
  description = "Azure region where resources are deployed (for example uksouth)."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID for provider authentication."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID for provider authentication."
  type        = string
}

variable "client_id" {
  description = "Deployment service principal client ID for provider authentication."
  type        = string
}

variable "client_secret" {
  description = "Deployment service principal client secret for provider authentication."
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Object ID of the deployment service principal (Enterprise Application object ID)."
  type        = string
}

variable "layer_sp_mode" {
  description = "Service-principal mode for per-layer identities: create or existing."
  type        = string

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID of the existing principal to reuse when layer_sp_mode=existing."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Object ID of the existing principal to reuse when layer_sp_mode=existing."
  type        = string
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether provider should recover soft-deleted Key Vaults on create."
  type        = bool
  default     = true
}

variable "enable_storage_shared_key" {
  description = "Keep shared key enabled for provider compatibility during initial provisioning."
  type        = bool
  default     = true
}

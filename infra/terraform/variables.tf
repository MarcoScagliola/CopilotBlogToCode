variable "tenant_id" {
  description = "Azure tenant ID used for deployment authentication."
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure subscription ID used for deployment authentication."
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Client ID of the deployment service principal."
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Client secret of the deployment service principal."
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Enterprise application object ID of the deployment service principal."
  type        = string
  sensitive   = true
}

variable "workload" {
  description = "Short workload code used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
}

variable "azure_region" {
  description = "Azure region for all provisioned resources."
  type        = string
}

variable "layer_sp_mode" {
  description = "Whether to create layer principals or reuse existing ones."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID of an existing layer service principal when layer_sp_mode is existing."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Enterprise application object ID of an existing layer service principal when layer_sp_mode is existing."
  type        = string
  default     = ""
}

variable "key_vault_recover_soft_deleted" {
  description = "Controls whether Terraform should attempt Key Vault soft-delete recovery during create/apply."
  type        = bool
  default     = true
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "client_id" {
  type        = string
  description = "Deployment principal application (client) ID."
}

variable "client_secret" {
  type        = string
  description = "Deployment principal client secret."
  sensitive   = true
}

variable "sp_object_id" {
  type        = string
  description = "Deployment principal object ID from Enterprise Applications."
}

variable "workload" {
  type        = string
  description = "Workload short name."
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
}

variable "azure_region" {
  type        = string
  description = "Azure region for deployment."
}

variable "layer_sp_mode" {
  type        = string
  description = "Layer service principal mode: create or existing."

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be either create or existing."
  }
}

variable "existing_layer_sp_client_id" {
  type        = string
  description = "Client ID for existing layer principal mode."
}

variable "existing_layer_sp_object_id" {
  type        = string
  description = "Object ID for existing layer principal mode."
}

variable "key_vault_recover_soft_deleted" {
  type        = bool
  description = "Recover soft deleted key vaults during apply."
  default     = true
}

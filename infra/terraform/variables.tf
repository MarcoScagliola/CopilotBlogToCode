variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "client_id" {
  type      = string
  sensitive = true
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "sp_object_id" {
  type      = string
  sensitive = true
}

variable "layer_sp_mode" {
  type    = string
  default = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be create or existing"
  }
}

variable "existing_layer_sp_client_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "existing_layer_sp_object_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "workload" {
  type    = string
  default = "blg"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "azure_region" {
  type    = string
  default = "uksouth"
}

variable "key_vault_recover_soft_deleted" {
  type    = bool
  default = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "client_id" {
  description = "Deployment principal application (client) ID"
  type        = string
}

variable "client_secret" {
  description = "Deployment principal client secret"
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Deployment principal service principal object ID"
  type        = string
}

variable "workload" {
  description = "Workload short name"
  type        = string
}

variable "environment" {
  description = "Environment short name"
  type        = string
}

variable "azure_region" {
  description = "Azure region"
  type        = string
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether provider recovers soft-deleted key vaults"
  type        = bool
  default     = true
}

variable "enable_shared_key" {
  description = "Keep shared key enabled for storage provisioning compatibility"
  type        = bool
  default     = true
}
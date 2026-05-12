# ---------------------------------------------------------------------------
# Identity — deployment principal credentials
# All values come from GitHub Secrets via TF_VAR_* environment variables.
# Never hardcode these values. See README.md for naming convention rationale.
# ---------------------------------------------------------------------------

variable "tenant_id" {
  description = "Azure tenant ID. Source: GitHub Secret AZURE_TENANT_ID."
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure subscription ID. Source: GitHub Secret AZURE_SUBSCRIPTION_ID."
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Deployment service principal Application (client) ID. Source: GitHub Secret AZURE_CLIENT_ID."
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Deployment service principal client secret. Source: GitHub Secret AZURE_CLIENT_SECRET."
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = <<-EOT
    Deployment service principal Enterprise Application object ID.
    This is the object ID from Microsoft Entra ID → Enterprise applications, NOT from App Registrations.
    Source: GitHub Secret AZURE_SP_OBJECT_ID.
  EOT
  type      = string
  sensitive = true
}

# ---------------------------------------------------------------------------
# Identity — layer service principal mode
# ---------------------------------------------------------------------------

variable "layer_sp_mode" {
  description = <<-EOT
    Controls how per-layer service principals are sourced.
      create   — Terraform creates a new Entra ID app registration and service principal per layer.
                 Requires Application.ReadWrite.All (or equivalent) in the target tenant.
      existing — Terraform reuses a principal identified by existing_layer_sp_client_id and
                 existing_layer_sp_object_id. No Entra ID directory permissions required.
  EOT
  type    = string
  default = "create"

  validation {
    condition     = contains(["create", "existing"], trimspace(var.layer_sp_mode))
    error_message = "layer_sp_mode must be \"create\" or \"existing\"."
  }
}

variable "existing_layer_sp_client_id" {
  description = <<-EOT
    Application (client) ID of the pre-existing layer service principal.
    Required when layer_sp_mode = "existing". Ignored when layer_sp_mode = "create".
    Source: GitHub Secret EXISTING_LAYER_SP_CLIENT_ID.
  EOT
  type      = string
  sensitive = true
  default   = ""
}

variable "existing_layer_sp_object_id" {
  description = <<-EOT
    Enterprise Application object ID of the pre-existing layer service principal.
    Must be the object ID from Microsoft Entra ID → Enterprise applications.
    Required when layer_sp_mode = "existing". Ignored when layer_sp_mode = "create".
    Source: GitHub Secret EXISTING_LAYER_SP_OBJECT_ID.
  EOT
  type      = string
  sensitive = true
  default   = ""
}

# ---------------------------------------------------------------------------
# Workload identity — Key Vault soft-delete recovery
# ---------------------------------------------------------------------------

variable "key_vault_recover_soft_deleted" {
  description = <<-EOT
    Whether the AzureRM provider should attempt to recover a soft-deleted Key Vault
    with the same name before creating a new one.
    Driven by the deploy workflow via TF_VAR_key_vault_recover_soft_deleted.
    Set to true for normal reruns; false for a guaranteed-fresh vault.
  EOT
  type    = bool
  default = true
}

# ---------------------------------------------------------------------------
# Workload
# ---------------------------------------------------------------------------

variable "workload" {
  description = "Short workload identifier used in all resource names. Default matches this repo's workload code."
  type        = string
  default     = "blg"
}

variable "environment" {
  description = "Target deployment environment (dev, prd, etc.). Used in resource names."
  type        = string
  default     = "dev"
}

variable "azure_region" {
  description = "Azure region for all resources. The region abbreviation is derived in locals.tf."
  type        = string
  default     = "uksouth"
}

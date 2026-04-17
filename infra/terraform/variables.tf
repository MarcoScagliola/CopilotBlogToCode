# ── Identity ──────────────────────────────────────────────────────────────────

variable "azure_tenant_id" {
  description = "Azure AD tenant ID. Supply via GitHub Secret / environment variable – never hardcode."
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure subscription ID. Supply via GitHub Secret / environment variable – never hardcode."
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Service principal client ID used by Terraform and Databricks CLI."
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Service principal client secret used by Terraform and Databricks CLI."
  type        = string
  sensitive   = true
}

variable "azure_sp_object_id" {
  description = "Object ID of the deployment service principal. Required for role assignments where the SP assigns roles to itself."
  type        = string
}

# ── Workload ───────────────────────────────────────────────────────────────────

variable "workload" {
  description = "Short identifier for the workload. Used as a naming component across all resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prd)."
  type        = string
}

variable "azure_region" {
  description = "Azure region for all resources (e.g. uksouth, eastus2)."
  type        = string
}

# ── Identity provisioning mode ────────────────────────────────────────────────

variable "layer_service_principal_mode" {
  description = <<-EOT
    Controls how per-layer service principals are provisioned.
      create   – Create new Entra ID applications and service principals (requires Directory permissions).
      existing – Reuse a single pre-existing service principal. Use when Entra app creation is restricted
                 by tenant policy. Provide existing_layer_sp_client_id and existing_layer_sp_object_id.
  EOT
  type    = string
  default = "create"

  validation {
    condition     = contains(["create", "existing"], var.layer_service_principal_mode)
    error_message = "layer_service_principal_mode must be 'create' or 'existing'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID of the pre-existing service principal. Required when layer_service_principal_mode = 'existing'."
  type        = string
  default     = ""
}

variable "existing_layer_sp_object_id" {
  description = "Object ID of the pre-existing service principal. Required when layer_service_principal_mode = 'existing'."
  type        = string
  default     = ""
}

# ── Storage ────────────────────────────────────────────────────────────────────

variable "storage_shared_key_enabled" {
  description = <<-EOT
    Allow shared-key (account key) access on ADLS Gen2 storage accounts.
    Defaults to true for provider compatibility: the AzureRM provider still polls
    blob storage with key-based auth during create/update, so disabling shared keys
    at provisioning time causes a KeyBasedAuthenticationNotPermitted error.
    Set to false as a post-deployment hardening step once all access is via managed identity.
  EOT
  type    = bool
  default = true
}

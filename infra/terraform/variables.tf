# ── Core deployment parameters ─────────────────────────────────────────────────

variable "workload" {
  description = "Short workload identifier used in resource names (e.g. blg)."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g. dev, prd)."
  type        = string
}

variable "azure_region" {
  description = "Azure region for all resources (e.g. uksouth)."
  type        = string
}

# ── Authentication ─────────────────────────────────────────────────────────────

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
  sensitive   = true
}

variable "deployment_sp_object_id" {
  description = "Object ID of the deployment service principal. Used to grant Key Vault access."
  type        = string
  sensitive   = true
}

# ── Layer service principals (existing mode) ───────────────────────────────────

variable "layer_sp_mode" {
  description = "How layer service principals are managed. 'existing' = provided externally; 'create' = created by Terraform."
  type        = string
  default     = "existing"

  validation {
    condition     = contains(["existing", "create"], var.layer_sp_mode)
    error_message = "layer_sp_mode must be 'existing' or 'create'."
  }
}

variable "existing_layer_sp_client_id" {
  description = "Client ID of the pre-existing service principal used for layer jobs (required when layer_sp_mode=existing)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "existing_layer_sp_object_id" {
  description = "Object ID of the pre-existing service principal used for layer jobs (required when layer_sp_mode=existing)."
  type        = string
  default     = ""
  sensitive   = true
}

# ── Feature flags ──────────────────────────────────────────────────────────────

variable "enable_access_connectors" {
  description = "Create Azure Databricks Access Connectors (required for Unity Catalog)."
  type        = bool
  default     = true
}

variable "key_vault_recover_soft_deleted" {
  description = "Whether the AzureRM provider should recover soft-deleted Key Vaults instead of failing."
  type        = bool
  default     = true
}

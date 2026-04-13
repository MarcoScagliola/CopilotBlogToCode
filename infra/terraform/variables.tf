# ---------------------------------------------------------------------------
# Sensitive variables – injected via TF_VAR_* from GitHub secrets
# ---------------------------------------------------------------------------

variable "azure_tenant_id" {
  description = "Azure Entra ID tenant ID. Injected via TF_VAR_azure_tenant_id."
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure subscription ID. Injected via TF_VAR_azure_subscription_id."
  type        = string
  sensitive   = true
}

variable "databricks_account_id" {
  description = "Databricks account ID (from accounts.azuredatabricks.net). Injected via TF_VAR_databricks_account_id."
  type        = string
  sensitive   = true
}

variable "databricks_metastore_id" {
  description = "Unity Catalog metastore ID to assign to the workspace. Injected via TF_VAR_databricks_metastore_id."
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure Service Principal client ID used for Databricks workspace provider auth."
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Service Principal client secret used for Databricks workspace provider auth."
  type        = string
  sensitive   = true
}

variable "jdbc_host" {
  description = "JDBC source database hostname. Stored in Key Vault."
  type        = string
  sensitive   = true
}

variable "jdbc_database" {
  description = "JDBC source database name. Stored in Key Vault."
  type        = string
  sensitive   = true
}

variable "jdbc_user" {
  description = "JDBC source database username. Stored in Key Vault."
  type        = string
  sensitive   = true
}

variable "jdbc_password" {
  description = "JDBC source database password. Stored in Key Vault."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Non-sensitive variables with defaults
# ---------------------------------------------------------------------------

variable "workload" {
  description = "Short workload identifier used in all resource names."
  type        = string
  default     = "blg"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.workload))
    error_message = "workload must be 2-6 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev or prd)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "environment must be 'dev' or 'prd'."
  }
}

variable "azure_region" {
  description = "Azure region for all resources (e.g. uksouth, eastus2)."
  type        = string
  default     = "uksouth"
}

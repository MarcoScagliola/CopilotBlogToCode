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

variable "databricks_account_id" {
  description = "Databricks account ID."
  type        = string
  sensitive   = true
}

variable "metastore_id" {
  description = "Existing Unity Catalog metastore ID."
  type        = string
  sensitive   = true
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

variable "jdbc_host" {
  description = "JDBC host stored in Key Vault for Bronze ingestion."
  type        = string
  sensitive   = true
}

variable "jdbc_database" {
  description = "JDBC database name stored in Key Vault for Bronze ingestion."
  type        = string
  sensitive   = true
}

variable "jdbc_user" {
  description = "JDBC user name stored in Key Vault for Bronze ingestion."
  type        = string
  sensitive   = true
}

variable "jdbc_password" {
  description = "JDBC password stored in Key Vault for Bronze ingestion."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Optional tags applied to Azure resources."
  type        = map(string)
  default     = {}
}

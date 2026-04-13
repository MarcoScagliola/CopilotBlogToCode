variable "workload" {
  description = "Short workload identifier used for naming."
  type        = string
  default     = "blg"
}

variable "environment" {
  description = "Deployment environment (for example: dev, tst, prd)."
  type        = string
  default     = "dev"
}

variable "azure_region" {
  description = "Azure region where resources are deployed."
  type        = string
  default     = "uksouth"
}

variable "azure_tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID for account-level configuration context."
  type        = string
}

variable "databricks_metastore_id" {
  description = "Unity Catalog metastore ID already provisioned in Databricks account."
  type        = string
}

variable "databricks_client_id" {
  description = "Client ID for the deployment service principal used by Databricks provider auth."
  type        = string
}

variable "databricks_client_secret" {
  description = "Client secret for the deployment service principal used by Databricks provider auth."
  type        = string
  sensitive   = true
}

variable "jdbc_host" {
  description = "JDBC source host."
  type        = string
}

variable "jdbc_database" {
  description = "JDBC source database."
  type        = string
}

variable "jdbc_user" {
  description = "JDBC source user name."
  type        = string
}

variable "jdbc_password" {
  description = "JDBC source password."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Optional tags applied to Azure resources."
  type        = map(string)
  default     = {}
}
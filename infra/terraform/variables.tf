variable "azure_subscription_id" {
  description = "Azure subscription ID where all resources will be deployed."
  type        = string
  # TODO: set in terraform.tfvars — see TODO.md
}

variable "azure_tenant_id" {
  description = "Microsoft Entra ID (Azure AD) tenant ID."
  type        = string
  # TODO: set in terraform.tfvars — see TODO.md
}

variable "azure_region" {
  description = "Azure region for all resources."
  type        = string
  default     = "uksouth"
}

variable "environment" {
  description = "Deployment environment label used in resource names (e.g. dev, test, prod)."
  type        = string
  default     = "prod"
}

variable "project_prefix" {
  description = "Short project prefix used in resource names (lowercase alphanumeric, no hyphens)."
  type        = string
  default     = "medallion"
}

variable "databricks_account_id" {
  description = "Databricks account UUID (shown in the Databricks account console)."
  type        = string
  # TODO: set in terraform.tfvars — see TODO.md
}

variable "databricks_metastore_id" {
  description = "Unity Catalog metastore UUID to assign to the new workspace. One metastore per account per region is typical."
  type        = string
  # TODO: set in terraform.tfvars — see TODO.md
}

variable "secret_scope_name" {
  description = "Name of the AKV-backed Databricks secret scope created in this workspace."
  type        = string
  default     = "akv-scope"
}

variable "tags" {
  description = "Tags applied to all Azure resources."
  type        = map(string)
  default = {
    project    = "secure-medallion"
    managed_by = "terraform"
  }
}

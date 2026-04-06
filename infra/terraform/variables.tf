variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID"
  type        = string
}

variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "databricks_workspace_url" {
  description = "Databricks workspace URL"
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID"
  type        = string
}

variable "unity_catalog_metastore_id" {
  description = "Unity Catalog metastore ID (optional / environment dependent)"
  type        = string
  default     = ""
}

variable "key_vault_name" {
  description = "Key Vault name"
  type        = string
}

variable "storage_container_name" {
  description = "Container name in each layer storage account"
  type        = string
  default     = "data"
}

variable "layer_storage_account_names" {
  description = "Storage account names keyed by layer"
  type        = map(string)
}

variable "layer_managed_identity_names" {
  description = "User-assigned managed identity names keyed by layer"
  type        = map(string)
}

variable "layer_access_connector_names" {
  description = "Databricks access connector names keyed by layer"
  type        = map(string)
}

variable "layer_service_principal_display_names" {
  description = "Service principal display names keyed by layer"
  type        = map(string)
}

variable "layer_storage_credential_names" {
  description = "Unity Catalog storage credential names keyed by layer"
  type        = map(string)
}

variable "layer_external_location_names" {
  description = "Unity Catalog external location names keyed by layer"
  type        = map(string)
}

variable "layer_catalog_names" {
  description = "Unity Catalog catalog names keyed by layer"
  type        = map(string)
}

variable "layer_schema_names" {
  description = "Unity Catalog schema names keyed by layer"
  type        = map(string)
}

variable "enable_networking" {
  description = "Set true to create VNet/subnets/NSG resources"
  type        = bool
  default     = false
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = ""
}

variable "vnet_address_space" {
  description = "Virtual network CIDR"
  type        = list(string)
  default     = []
}

variable "public_subnet_name" {
  description = "Public subnet name"
  type        = string
  default     = ""
}

variable "public_subnet_address_prefixes" {
  description = "Public subnet CIDR(s)"
  type        = list(string)
  default     = []
}

variable "private_subnet_name" {
  description = "Private subnet name"
  type        = string
  default     = ""
}

variable "private_subnet_address_prefixes" {
  description = "Private subnet CIDR(s)"
  type        = list(string)
  default     = []
}

variable "nsg_name" {
  description = "Network security group name"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for Azure resources"
  type        = map(string)
  default     = {}
}

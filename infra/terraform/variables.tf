variable "azure_tenant_id" {
  description = "Azure Tenant ID (Entra ID)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.azure_tenant_id))
    error_message = "azure_tenant_id must be a valid UUID."
  }
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.azure_subscription_id))
    error_message = "azure_subscription_id must be a valid UUID."
  }
}

variable "databricks_account_id" {
  description = "Databricks Account ID (numeric)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9]{15}$", var.databricks_account_id))
    error_message = "databricks_account_id must be a 15-digit numeric ID."
  }
}

variable "databricks_metastore_id" {
  description = "Databricks Metastore ID (e.g., metastore-12345678-abcd-1234-abcd-123456789abc)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^metastore-[a-f0-9-]+$", var.databricks_metastore_id))
    error_message = "databricks_metastore_id must start with 'metastore-' followed by a UUID."
  }
}

variable "databricks_client_id" {
  description = "Databricks OAuth client ID (service principal ID)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.databricks_client_id))
    error_message = "databricks_client_id must be a valid UUID."
  }
}

variable "databricks_client_secret" {
  description = "Databricks OAuth client secret"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.databricks_client_secret) > 0
    error_message = "databricks_client_secret must not be empty."
  }
}

variable "jdbc_host" {
  description = "JDBC source database hostname"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.jdbc_host))
    error_message = "jdbc_host must be a valid hostname or IP address."
  }
}

variable "jdbc_database" {
  description = "JDBC source database name"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jdbc_database) > 0
    error_message = "jdbc_database must not be empty."
  }
}

variable "jdbc_user" {
  description = "JDBC source database username"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jdbc_user) > 0
    error_message = "jdbc_user must not be empty."
  }
}

variable "jdbc_password" {
  description = "JDBC source database password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jdbc_password) > 0
    error_message = "jdbc_password must not be empty."
  }
}

# Operational defaults (can be overridden)

variable "workload" {
  description = "Workload name (alphanumeric, 4-6 chars)"
  type        = string
  default     = "blg"

  validation {
    condition     = can(regex("^[a-z0-9]{4,6}$", var.workload))
    error_message = "workload must be 4-6 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "azure_region" {
  description = "Azure region (e.g., uksouth, eastus, westeurope)"
  type        = string
  default     = "uksouth"

  validation {
    condition     = length(var.azure_region) > 0
    error_message = "azure_region must not be empty."
  }
}

variable "resource_tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "medallion-architecture"
    CreatedBy   = "Terraform"
  }
}

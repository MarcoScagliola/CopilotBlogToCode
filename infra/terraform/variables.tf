variable "azure_tenant_id" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_region" {
  type = string
}

variable "workload" {
  type = string
}

variable "environment" {
  type = string
}

variable "databricks_account_id" {
  type = string
}

variable "databricks_metastore_id" {
  type = string
}

variable "databricks_workspace_pat_token" {
  type      = string
  sensitive = true
}

variable "databricks_client_id" {
  type = string
}

variable "databricks_client_secret" {
  type      = string
  sensitive = true
}

variable "layers" {
  type = map(object({
    node_type_id = string
    num_workers  = number
    cron         = string
    alert_email  = string
  }))
}

variable "orchestrator" {
  type = object({
    node_type_id = string
    num_workers  = number
    cron         = string
    alert_email  = string
  })
}

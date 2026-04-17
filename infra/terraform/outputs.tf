output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
}

output "databricks_workspace_resource_id" {
  value = azurerm_databricks_workspace.this.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "secret_scope_name" {
  value = local.secret_scope_name
}

output "bronze_sp_application_id" {
  value = local.layer_application_ids["bronze"]
}

output "silver_sp_application_id" {
  value = local.layer_application_ids["silver"]
}

output "gold_sp_application_id" {
  value = local.layer_application_ids["gold"]
}

output "bronze_catalog_name" {
  value = databricks_catalog.layer["bronze"].name
}

output "silver_catalog_name" {
  value = databricks_catalog.layer["silver"].name
}

output "gold_catalog_name" {
  value = databricks_catalog.layer["gold"].name
}

output "bronze_schema_name" {
  value = databricks_schema.layer["bronze"].name
}

output "silver_schema_name" {
  value = databricks_schema.layer["silver"].name
}

output "gold_schema_name" {
  value = databricks_schema.layer["gold"].name
}

output "bronze_access_connector_id" {
  value = azurerm_databricks_access_connector.layer["bronze"].id
}

output "silver_access_connector_id" {
  value = azurerm_databricks_access_connector.layer["silver"].id
}

output "gold_access_connector_id" {
  value = azurerm_databricks_access_connector.layer["gold"].id
}

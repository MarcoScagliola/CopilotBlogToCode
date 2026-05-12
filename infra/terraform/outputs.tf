output "databricks_workspace_url" {
  value = "https://${azurerm_databricks_workspace.main.workspace_url}"
}

output "databricks_workspace_resource_id" {
  value = azurerm_databricks_workspace.main.id
}

output "bronze_catalog" { value = "bronze" }
output "silver_catalog" { value = "silver" }
output "gold_catalog" { value = "gold" }

output "bronze_schema" { value = "main" }
output "silver_schema" { value = "main" }
output "gold_schema" { value = "main" }

output "bronze_storage_account" { value = azurerm_storage_account.layer["bronze"].name }
output "silver_storage_account" { value = azurerm_storage_account.layer["silver"].name }
output "gold_storage_account" { value = azurerm_storage_account.layer["gold"].name }

output "bronze_access_connector_id" { value = azurerm_databricks_access_connector.layer["bronze"].id }
output "silver_access_connector_id" { value = azurerm_databricks_access_connector.layer["silver"].id }
output "gold_access_connector_id" { value = azurerm_databricks_access_connector.layer["gold"].id }

output "bronze_principal_client_id" {
  value     = local.resolved_layer_client_ids["bronze"]
  sensitive = true
}

output "silver_principal_client_id" {
  value     = local.resolved_layer_client_ids["silver"]
  sensitive = true
}

output "gold_principal_client_id" {
  value     = local.resolved_layer_client_ids["gold"]
  sensitive = true
}

output "layer_principal_client_ids" {
  value     = local.resolved_layer_client_ids
  sensitive = true
}

output "secret_scope" {
  value = local.secret_scope_name
}

output "secret_scope_name" {
  value = local.secret_scope_name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "layer_storage_account_names" {
  value = {
    bronze = azurerm_storage_account.layer["bronze"].name
    silver = azurerm_storage_account.layer["silver"].name
    gold   = azurerm_storage_account.layer["gold"].name
  }
}

output "layer_access_connector_ids" {
  value = {
    bronze = azurerm_databricks_access_connector.layer["bronze"].id
    silver = azurerm_databricks_access_connector.layer["silver"].id
    gold   = azurerm_databricks_access_connector.layer["gold"].id
  }
}

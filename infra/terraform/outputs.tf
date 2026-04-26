output "resource_group_name" {
  value = azurerm_resource_group.platform.name
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
}

output "databricks_workspace_resource_id" {
  value = azurerm_databricks_workspace.this.id
}

output "secret_scope_name" {
  value = local.secret_scope_name
}

output "layer_storage_account_names" {
  value = {
    for layer in local.layer_names :
    layer => azurerm_storage_account.layer[layer].name
  }
}

output "layer_access_connector_ids" {
  value = {
    for layer in local.layer_names :
    layer => azurerm_databricks_access_connector.layer[layer].id
  }
}

output "layer_principal_client_ids" {
  value = local.layer_principal_client_ids
}

output "bronze_catalog_name" {
  value = local.layer_map["bronze"].catalog_name
}

output "silver_catalog_name" {
  value = local.layer_map["silver"].catalog_name
}

output "gold_catalog_name" {
  value = local.layer_map["gold"].catalog_name
}

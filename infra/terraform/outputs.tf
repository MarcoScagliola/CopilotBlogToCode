output "resource_group_id" {
  value = azurerm_resource_group.this.id
}

output "vnet_id" {
  value = var.enable_networking ? azurerm_virtual_network.this[0].id : null
}

output "public_subnet_id" {
  value = var.enable_networking ? azurerm_subnet.public[0].id : null
}

output "private_subnet_id" {
  value = var.enable_networking ? azurerm_subnet.private[0].id : null
}

output "layer_storage_account_ids" {
  value = {
    for layer, account in azurerm_storage_account.layer :
    layer => account.id
  }
}

output "layer_access_connector_ids" {
  value = {
    for layer, connector in azurerm_databricks_access_connector.layer :
    layer => connector.id
  }
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "layer_service_principal_application_ids" {
  value = {
    for layer, app in azuread_application.layer :
    layer => app.client_id
  }
}

output "layer_catalog_names" {
  value = {
    for layer, catalog in databricks_catalog.layer :
    layer => catalog.name
  }
}

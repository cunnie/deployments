output "resource_group_name" {
  value = azurerm_resource_group.sslip_io.name
}

output "network_interface_id" {
  value = azurerm_network_interface.sslip_io.id
}

output "azurerm_storage_account_primary_blob_endpoint" {
  value = azurerm_storage_account.sslip_io.primary_blob_endpoint
}

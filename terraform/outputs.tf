output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "adls_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "adls_dfs_endpoint" {
  value = azurerm_storage_account.datalake.primary_dfs_endpoint
}

output "data_factory_name" {
  value = azurerm_data_factory.main.name
}

output "function_app_name" {
  value = azurerm_function_app_flex_consumption.main.name
}

output "synapse_workspace_name" {
  value = azurerm_synapse_workspace.main.name
}

output "synapse_sql_endpoint" {
  value = azurerm_synapse_workspace.main.connectivity_endpoints["sql"]
}

output "dedicated_sql_pool_name" {
  value = azurerm_synapse_sql_pool.warehouse.name
}

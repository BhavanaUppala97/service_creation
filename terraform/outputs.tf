output "resource_group_name" {
  value = azurerm_resource_group.adf_rg.name
}

output "data_factory_name" {
  value = azurerm_data_factory.adf.name
}

output "data_factory_id" {
  value = azurerm_data_factory.adf.id
}

output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "linked_service_name" {
  value = azurerm_data_factory_linked_service_data_lake_storage_gen2.adls.name
}

output "pipeline_name" {
  value = azurerm_data_factory_pipeline.sample.name
}

output "synapse_workspace_name" {
  value = azurerm_synapse_workspace.synapse_workspace.name
}

output "synapse_workspace_id" {
  value = azurerm_synapse_workspace.synapse_workspace.id
}

output "synapse_spark_pool_name" {
  value = azurerm_synapse_spark_pool.spark_pool.name
}

output "synapse_storage_account_name" {
  value = azurerm_storage_account.synapse_storage.name
}

output "synapse_dev_endpoint" {
  value = azurerm_synapse_workspace.synapse_workspace.connectivity_endpoints["dev"]
}

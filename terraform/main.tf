# 1. Resource Group
resource "azurerm_resource_group" "adf_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# 2. Azure Data Lake Storage Gen2
resource "azurerm_storage_account" "datalake" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.adf_rg.name
  location                 = azurerm_resource_group.adf_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  account_kind             = "StorageV2"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
}

# 3. Data Lake filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "raw" {
  name               = "raw"
  storage_account_id = azurerm_storage_account.datalake.id
}

# 4. Azure Data Factory
resource "azurerm_data_factory" "adf" {
  name                = var.data_factory_name
  location            = azurerm_resource_group.adf_rg.location
  resource_group_name = azurerm_resource_group.adf_rg.name

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# 5. Give ADF access to Data Lake
resource "azurerm_role_assignment" "adf_storage" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

# 6. Linked Service: ADF to ADLS Gen2
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adls" {
  name                 = "LS_ADLS_Gen2"
  data_factory_id      = azurerm_data_factory.adf.id
  url                  = azurerm_storage_account.datalake.primary_dfs_endpoint
  use_managed_identity = true

  depends_on = [
    azurerm_role_assignment.adf_storage
  ]
}

# 7. CSV Dataset in the raw filesystem
resource "azurerm_data_factory_dataset_delimited_text" "source_csv" {
  name                = "DS_Source_CSV"
  data_factory_id     = azurerm_data_factory.adf.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adls.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.raw.name
    path        = "input"
    filename    = "sample.csv"
  }

  column_delimiter    = ","
  first_row_as_header = true
}

# 8. Example ADF Pipeline
resource "azurerm_data_factory_pipeline" "sample" {
  name            = "PL_Sample_Pipeline"
  data_factory_id = azurerm_data_factory.adf.id

  activities_json = jsonencode([
    {
      name = "WaitActivity"
      type = "Wait"
      typeProperties = {
        waitTimeInSeconds = 5
      }
    }
  ])
}

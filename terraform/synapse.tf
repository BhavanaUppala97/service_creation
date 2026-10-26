
# ---------------------------------------
# Azure Synapse Resource Group
# ---------------------------------------

resource "azurerm_resource_group" "synapse_rg" {
  name     = var.synapse_resource_group
  location = var.synapse_location
}

# ---------------------------------------
# Synapse Data Lake Storage Gen2
# ---------------------------------------


resource "azurerm_storage_account" "synapse_storage" {
  name                = var.synapse_storage_name
  resource_group_name = azurerm_resource_group.synapse_rg.name
  location            = azurerm_resource_group.synapse_rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  is_hns_enabled  = true
  min_tls_version = "TLS1_2"
}


# ---------------------------------------
# Synapse Data Lake Filesystem
# ---------------------------------------

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_fs" {
  name               = "synapse"
  storage_account_id = azurerm_storage_account.synapse_storage.id
}

# ---------------------------------------
# Azure Synapse Analytics Workspace
# ---------------------------------------

resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                = var.synapse_workspace_name
  resource_group_name = azurerm_resource_group.synapse_rg.name
  location            = azurerm_resource_group.synapse_rg.location

  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_fs.id

  sql_administrator_login          = "synapseadmin"
  sql_administrator_login_password = var.synapse_sql_password

  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------
# Grant Synapse access to default lake
# ---------------------------------------

resource "azurerm_role_assignment" "synapse_storage_access" {
  scope                = azurerm_storage_account.synapse_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse_workspace.identity[0].principal_id
}

# ---------------------------------------
# Apache Spark Pool
# ---------------------------------------

resource "azurerm_synapse_spark_pool" "spark_pool" {
  name                 = "sparkpool01"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id

  node_size_family = "MemoryOptimized"
  node_size        = "Small"
  spark_version    = "3.5"
  node_count       = 3

  auto_pause {
    delay_in_minutes = 15
  }
}

variable "synapse_user_object_id" {
  description = "Microsoft Entra Object ID of the user"
  type        = string
}

resource "azurerm_synapse_role_assignment" "sql_admin" {

depends_on = [
  azurerm_synapse_firewall_rule.github_runner
]
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id

  role_name      = "Synapse SQL Administrator"
  principal_id   = var.synapse_user_object_id
  principal_type = "User"
}


resource "azurerm_synapse_firewall_rule" "github_runner" {
  name                 = "AllowGitHubRunner"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id

  start_ip_address = "20.104.156.185"
  end_ip_address   = "20.104.156.185"
}

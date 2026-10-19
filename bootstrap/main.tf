terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}


resource "azurerm_resource_group" "state" {
  name     = "rg-terraform-state"
  location = "westus"
}
 
resource "azurerm_storage_account" "state" {
  name                     = "storagemyprojectdev12345"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}


resource "azurerm_user_assigned_identity" "github" {
  name                = "id-github-terraform"
  location            = var.location
  resource_group_name = azurerm_resource_group.state.name
}

resource "azurerm_federated_identity_credential" "main" {
  name                = "github-main"
  resource_group_name = azurerm_resource_group.state.name
  parent_id           = azurerm_user_assigned_identity.github.id
  issuer              = "https://token.actions.githubusercontent.com"
  audience            = ["api://AzureADTokenExchange"]
  subject             = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"
}

resource "azurerm_federated_identity_credential" "pr" {
  name                = "github-pr"
  resource_group_name = azurerm_resource_group.state.name
  parent_id           = azurerm_user_assigned_identity.github.id
  issuer              = "https://token.actions.githubusercontent.com"
  audience            = ["api://AzureADTokenExchange"]
  subject             = "repo:${var.github_owner}/${var.github_repo}:pull_request"
}

resource "azurerm_role_assignment" "deploy" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_assignment" "storage_state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}
resource "azurerm_role_assignment" "rbac_admin" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

output "github_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

output "state_storage_account" {
  value = azurerm_storage_account.state.name
}

output "state_resource_group" {
  value = azurerm_resource_group.state.name
}

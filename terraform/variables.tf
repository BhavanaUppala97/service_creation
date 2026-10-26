variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "westus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-adf-dev"
}

variable "data_factory_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

# Synapse configuration

variable "synapse_resource_group" {
  type    = string
  default = "rg-synapse-dev"
}

variable "synapse_location" {
  type    = string
  default = "westus"
}

variable "synapse_storage_name" {
  type    = string
  default = "synapselakevenkat2026"
}

variable "synapse_workspace_name" {
  type    = string
  default = "synapse-venkat-dev-2026"
}

variable "synapse_sql_password" {
  type      = string
  sensitive = true
}

variable "synapse_user_object_id" {
  type        = string
  description = "Object ID of the Synapse SQL administrator"
}


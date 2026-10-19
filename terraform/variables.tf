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

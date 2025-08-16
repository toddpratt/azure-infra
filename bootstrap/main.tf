terraform {
  backend "local" {}   # store state locally just for bootstrap
}

provider "azurerm" {
  features {}
  use_cli = true
}

resource "azurerm_resource_group" "rg" {
  name     = "tf-bootstrap-rg"
  location = "eastus"
}

resource "azurerm_storage_account" "sa" {
  name                     = "tfstate${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}


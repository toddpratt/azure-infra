terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatehub99676"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

module "network" {
  source              = "./modules/network"
  resource_group_name = "rg-hub"
  location            = "eastus2"
  name_prefix         = "hub"
  vnet_cidr           = "10.0.0.0/16"
  subnets = {
    jump            = "10.0.1.0/24"
    cicd            = "10.0.2.0/24"
    observability   = "10.0.3.0/24"
  }
}


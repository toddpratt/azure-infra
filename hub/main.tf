terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatehub99676"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "backend_sa" { default = "tfstate-hub-99676" }
variable "env_name"    { default = "hub" }
variable "resource_group" { default = "rg-hub" }
variable "location"    { default = "eastus2" }

module "network" {
  source              = "./modules/network"
  resource_group_name = var.resource_group
  location            = var.location
  name_prefix         = "hub"
  vnet_cidr           = "10.0.0.0/16"
  subnets = {
    jump            = "10.0.1.0/24"
    cicd            = "10.0.2.0/24"
    observability   = "10.0.3.0/24"
  }
}

module "jumpbox" {
  source              = "../modules/vm"
  name                = "jumpbox"
  resource_group_name = var.resource_group
  location            = var.location
  subnet_id           = module.network.subnet_ids["jump"]
  ssh_public_key      = "~/.ssh/id_rsa.pub"
  create_public_ip    = true
}


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
variable "vnet_cidr"    { default = "10.0.0.0/16" }
variable "subnets"    {
  default = {
    jump            = "10.0.1.0/24"
    cicd            = "10.0.2.0/24"
    observability   = "10.0.3.0/24"
  }
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

module "network" {
  source              = "./modules/network"
  resource_group_name = var.resource_group
  location            = var.location
  name_prefix         = "hub"
  vnet_cidr           = var.vnet_cidr
  subnets = var.subnets
}

module "jumpbox" {
  source              = "../modules/vm"
  name                = "jumpbox"
  resource_group_name = var.resource_group
  location            = var.location
  subnet_id           = module.network.subnet_ids["jump"]
  ssh_public_key      = file(var.ssh_public_key_path)
  create_public_ip    = true
}

output "hub_vnet_id" {
  value = module.network.vnet_id
}

output "hub_vnet_name" {
  value = module.network.vnet_name
}

output "hub_subnets" {
  value = var.subnets
}

output "jump_private_ip" {
  value = module.jumpbox.jump_private_ip
}

output "jump_public_ip" {
  value = module.jumpbox.jump_public_ip
}

output "hub_resource_group" {
  value = var.resource_group
}


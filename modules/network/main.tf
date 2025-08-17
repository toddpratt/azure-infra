terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.114"
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "vnet_peering_to" {
  name      = "vnet_peering_to"
  source    = "../../modules/vnet_peering"
  rg_name   = var.resource_group_name
  vnet_name = azurerm_virtual_network.vnet.name
  peer_id   = var.peer_to_vnet_id
}

module "vnet_peering_from" {
  name      = "vnet_peering_from"
  source    = "../../modules/vnet_peering"
  rg_name   = var.peer_network_rg
  vnet_name = var.peer_to_vnet_name
  peer_id   = azurerm_virtual_network.vnet.id
}

module "proxy_subnet" {
  source          = "../../modules/base_subnet"
  name_prefix     = "proxy"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.proxy
  jumphost_subnet     = var.jump_subnet
  metrics_subnet  = var.metrics_subnet
  allow_rules = [
    {
      source_ip  = "*"
      port_range = "80"
    },
    {
      source_ip  = "*"
      port_range = "443"
    },
  ]
}

module "api_subnet" {
  source          = "../../modules/../modules/base_subnet"
  name_prefix     = "api"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.api
  jumphost_subnet     = var.jump_subnet
  metrics_subnet  = var.metrics_subnet
  allow_rules = [
    {
      source_ip  = var.subnets.proxy
      port_range = "8080"
    },
    {
      source_ip  = var.subnets.proxy
      port_range = "8081"
    },
  ]
}

module "web_subnet" {
  source          = "../../modules/base_subnet"
  name_prefix     = "web"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.web
  jumphost_subnet     = var.jump_subnet
  metrics_subnet  = var.metrics_subnet
  allow_rules = [
    {
      source_ip  = var.subnets.proxy
      port_range = "8080"
    },
    {
      source_ip  = var.subnets.proxy
      port_range = "8081"
    },
  ]
}

module "db_subnet" {
  source          = "../../modules/base_subnet"
  name_prefix     = "db"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.db
  jumphost_subnet     = var.jump_subnet
  metrics_subnet  = var.metrics_subnet
  allow_rules = [
    {
      source_ip  = var.subnets.api
      port_range = "3306"
    },
  ]
}


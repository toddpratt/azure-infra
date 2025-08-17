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

module "jump_subnet" {
  source      = "../../../modules/base_subnet"
  name_prefix = "jump"
  rg_name     = azurerm_resource_group.rg.name
  location    = azurerm_resource_group.rg.location
  vnet_name   = azurerm_virtual_network.vnet.name
  subnet      = var.subnets.jump
  public_ssh  = true
  metrics_subnet  = var.subnets.metrics
}

module "cicd_subnet" {
  source          = "../../../modules/base_subnet"
  name_prefix     = "cicd"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.cicd
  jumphost_subnet = var.subnets.jump
  metrics_subnet  = var.subnets.metrics
}

module "observability_subnet" {
  source          = "../../../modules/base_subnet"
  name_prefix     = "observability"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.observability
  jumphost_subnet = var.subnets.jump
  metrics_subnet  = var.subnets.metrics
}

module "metrics_subnet" {
  source          = "../../../modules/base_subnet"
  name_prefix     = "metrics"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.metrics
  jumphost_subnet = var.subnets.jump
  metrics_subnet  = var.subnets.metrics
  allow_rules = [
    { # Prometheus web ui / api
      source_ip  = var.subnets.observability
      port_range = "9090"
    }
  ]
}

module "logs_subnet" {
  source          = "../../../modules/base_subnet"
  name_prefix     = "logs"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.logs
  jumphost_subnet = var.subnets.jump
  metrics_subnet  = var.subnets.metrics
  allow_rules = [
    { # Loki Port
      source_ip  = "*"
      port_range = "3100"
    }
  ]
}

module "trace_subnet" {
  source          = "../../../modules/base_subnet"
  name_prefix     = "trace"
  rg_name         = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  vnet_name       = azurerm_virtual_network.vnet.name
  subnet          = var.subnets.trace
  jumphost_subnet = var.subnets.jump
  metrics_subnet  = var.subnets.metrics
}


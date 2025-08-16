terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.114"
    }
  }
}

variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "name_prefix"         { type = string }
variable "vnet_cidr"           { type = string }
variable "subnets"             { type = map(string) }

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

resource "azurerm_subnet" "jump" {
  name                 = "jump"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnets["jump"]]
}

resource "azurerm_subnet" "cicd" {
  name                 = "cicd"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnets["cicd"]]
}

resource "azurerm_subnet" "observability" {
  name                 = "observability"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnets["observability"]]
}

resource "azurerm_network_security_group" "jump" {
  name                = "${var.name_prefix}-nsg-jump"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "cicd" {
  name                = "${var.name_prefix}-nsg-cicd"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "observability" {
  name                = "${var.name_prefix}-nsg-observability"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "jump_deny_vnet" {
  name                        = "deny-vnet-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.jump.name
}

resource "azurerm_network_security_rule" "jump_allow_jump_ssh" {
  name                        = "allow-jump-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.jump.name
}

resource "azurerm_network_security_rule" "cicd_deny_vnet" {
  name                        = "deny-vnet-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.cicd.name
}

resource "azurerm_network_security_rule" "cicd_allow_jump" {
  name                        = "allow-ports"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = azurerm_subnet.jump.address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.cicd.name
}

resource "azurerm_network_security_rule" "observability_deny_vnet" {
  name                        = "deny-vnet-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.observability.name
}

resource "azurerm_network_security_rule" "observability_allow_jump" {
  name                        = "allow-ports"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefixes     = azurerm_subnet.jump.address_prefixes
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.observability.name
}

resource "azurerm_subnet_network_security_group_association" "jump_assoc" {
  subnet_id                 = azurerm_subnet.jump.id
  network_security_group_id = azurerm_network_security_group.jump.id
}

resource "azurerm_subnet_network_security_group_association" "cicd_assoc" {
  subnet_id                 = azurerm_subnet.cicd.id
  network_security_group_id = azurerm_network_security_group.cicd.id
}

resource "azurerm_subnet_network_security_group_association" "observability_assoc" {
  subnet_id                 = azurerm_subnet.observability.id
  network_security_group_id = azurerm_network_security_group.observability.id
}

output "subnet_ids" {
  value = {
    jump          = azurerm_subnet.jump.id
    cicd          = azurerm_subnet.cicd.id
    observability = azurerm_subnet.observability.id
  }
}

output "nsg_ids" {
  value = {
    jump = azurerm_network_security_group.jump.id
    cicd   = azurerm_network_security_group.cicd.id
    observability    = azurerm_network_security_group.observability.id
  }
}


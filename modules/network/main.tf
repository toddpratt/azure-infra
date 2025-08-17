terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.114"
    }
  }
}

# ---------------------------
# Inputs
# ---------------------------
variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "name_prefix"         { type = string }
variable "vnet_cidr"           { type = string }
variable "subnets"             { type = map(string) }
variable "peer_to_vnet_id" {
  type        = string
  default     = null
}
variable "peer_to_vnet_name" {
  type        = string
  default     = null
}
variable "peer_network_rg" {
  type        = string
  default     = null
}
variable "jump_private_ip" { type = string }

# ---------------------------
# Resource Group + VNet + Subnets
# ---------------------------
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

resource "azurerm_virtual_network_peering" "to_hub" {
  name                         = "${var.name_prefix}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = var.peer_to_vnet_id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "from_hub" {
  name                         = "hub-to-${var.name_prefix}"
  resource_group_name          = var.peer_network_rg
  virtual_network_name         = var.peer_to_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  allow_virtual_network_access = true
}

resource "azurerm_subnet" "proxy" {
  name                 = "proxy"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnets["proxy"]]
}

resource "azurerm_subnet" "api" {
  name                 = "api"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnets["api"]]
}

resource "azurerm_subnet" "web" {
  name                 = "web"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnets["web"]]
}

resource "azurerm_subnet" "db" {
  name                 = "db"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnets["db"]]
}

# ---------------------------
# NSGs (one per subnet)
# ---------------------------
resource "azurerm_network_security_group" "proxy" {
  name                = "${var.name_prefix}-nsg-proxy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "api" {
  name                = "${var.name_prefix}-nsg-api"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "web" {
  name                = "${var.name_prefix}-nsg-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "db" {
  name                = "${var.name_prefix}-nsg-db"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# ---------------------------
# Inbound segmentation: deny-all VNet → subnet, then explicit allows
# Lower priority number = higher precedence
# ---------------------------

# WEB NSG: deny-all from VNet, then allow proxy -> web : 8080, 8081
resource "azurerm_network_security_rule" "web_deny_vnet" {
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
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "web_allow_proxy_8080" {
  name                        = "allow-proxy-8080"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefixes     = azurerm_subnet.proxy.address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "web_allow_proxy_8081" {
  name                        = "allow-proxy-8081"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8081"
  source_address_prefixes     = azurerm_subnet.proxy.address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "web_allow_jump_host" {
  name                        = "allow-jumphost"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = [var.jump_private_ip]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web.name
}

# API NSG: deny-all from VNet, then allow proxy -> api : 8080, 8081
resource "azurerm_network_security_rule" "api_deny_vnet" {
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
  network_security_group_name = azurerm_network_security_group.api.name
}

resource "azurerm_network_security_rule" "api_allow_proxy_8080" {
  name                        = "allow-proxy-8080"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefixes     = azurerm_subnet.proxy.address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.api.name
}

resource "azurerm_network_security_rule" "api_allow_proxy_8081" {
  name                        = "allow-proxy-8081"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8081"
  source_address_prefixes     = azurerm_subnet.proxy.address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.api.name
}

resource "azurerm_network_security_rule" "api_allow_jump_host" {
  name                        = "allow-jumphost"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = [var.jump_private_ip]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.api.name
}

# DB NSG: deny-all from VNet, then allow api -> db : 3306
resource "azurerm_network_security_rule" "db_deny_vnet" {
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
  network_security_group_name = azurerm_network_security_group.db.name
}

resource "azurerm_network_security_rule" "db_allow_api_3306" {
  name                        = "allow-api-3306"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefixes     = azurerm_subnet.api.address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.db.name
}

resource "azurerm_network_security_rule" "db_allow_jump_host" {
  name                        = "allow-jumphost"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = [var.jump_private_ip]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.db.name
}

# (Optional) PROXY NSG: if you want to lock inbound to proxy from VNet too
resource "azurerm_network_security_rule" "proxy_deny_vnet" {
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
  network_security_group_name = azurerm_network_security_group.proxy.name
}

resource "azurerm_network_security_rule" "proxy_allow_jump_host" {
  name                        = "allow-jumphost"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = [var.jump_private_ip]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.proxy.name
}
# ---------------------------
# Associations: attach NSGs to subnets
# ---------------------------
resource "azurerm_subnet_network_security_group_association" "proxy_assoc" {
  subnet_id                 = azurerm_subnet.proxy.id
  network_security_group_id = azurerm_network_security_group.proxy.id
}

resource "azurerm_subnet_network_security_group_association" "api_assoc" {
  subnet_id                 = azurerm_subnet.api.id
  network_security_group_id = azurerm_network_security_group.api.id
}

resource "azurerm_subnet_network_security_group_association" "web_assoc" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

# ---------------------------
# Outputs (handy for debugging)
# ---------------------------
output "subnet_ids" {
  value = {
    proxy = azurerm_subnet.proxy.id
    api   = azurerm_subnet.api.id
    web   = azurerm_subnet.web.id
    db    = azurerm_subnet.db.id
  }
}

output "nsg_ids" {
  value = {
    proxy = azurerm_network_security_group.proxy.id
    api   = azurerm_network_security_group.api.id
    web   = azurerm_network_security_group.web.id
    db    = azurerm_network_security_group.db.id
  }
}


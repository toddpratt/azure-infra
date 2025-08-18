
resource "azurerm_virtual_network_peering" "this" {
  name                         = var.name
  resource_group_name          = var.rg_name
  virtual_network_name         = var.vnet_name
  remote_virtual_network_id    = var.peer_id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  allow_virtual_network_access = true
}


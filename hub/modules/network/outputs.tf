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

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}


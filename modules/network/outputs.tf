
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


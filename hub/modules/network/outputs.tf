output "subnet_ids" {
  value = {
    jump          = module.jump_subnet.subnet_id
    cicd          = module.cicd_subnet.subnet_id
    observability = module.observability_subnet.subnet_id
    metrics       = module.metrics_subnet.subnet_id
    logs          = module.logs_subnet.subnet_id
    trace         = module.trace_subnet.subnet_id
  }
}

output "nsg_ids" {
  value = {
    jump          = module.jump_subnet.nsg_id
    cicd          = module.cicd_subnet.nsg_id
    observability = module.observability_subnet.nsg_id
    metrics       = module.metrics_subnet.nsg_id
    logs          = module.logs_subnet.nsg_id
    trace         = module.trace_subnet.nsg_id
  }
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}


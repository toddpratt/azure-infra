
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


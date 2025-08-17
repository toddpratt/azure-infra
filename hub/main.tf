
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


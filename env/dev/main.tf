
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatehub49131"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

variable "resource_group" { default = "rg-dev-app" }
variable "location"    { default = "eastus2" }

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = var.resource_group
  location            = var.location
  name_prefix         = "dev-app"
  vnet_cidr           = "10.10.0.0/16"
  peer_to_vnet_name   = data.terraform_remote_state.hub.outputs.hub_vnet_name
  peer_to_vnet_id     = data.terraform_remote_state.hub.outputs.hub_vnet_id
  peer_network_rg     = data.terraform_remote_state.hub.outputs.hub_resource_group
  jump_subnet         = data.terraform_remote_state.hub.outputs.hub_subnets.jump
  metrics_subnet      = data.terraform_remote_state.hub.outputs.hub_subnets.metrics
  subnets = {
    proxy = "10.10.1.0/24"
    api   = "10.10.2.0/24"
    web   = "10.10.3.0/24"
    db    = "10.10.4.0/24"
  }
}

module "db" {
  source              = "../../modules/vm"
  name                = "db"
  resource_group_name = var.resource_group
  location            = var.location
  subnet_id           = module.network.subnet_ids["db"]
  ssh_public_key      = file(var.ssh_public_key_path)
  create_public_ip    = false
}


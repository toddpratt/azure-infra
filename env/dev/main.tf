
module "network" {
  source              = "../../modules/network"
  resource_group_name = "rg-dev-app"
  location            = "eastus2"
  name_prefix         = "dev-app"
  vnet_cidr           = "10.10.0.0/16"
  subnets = {
    proxy = "10.10.1.0/24"
    api   = "10.10.2.0/24"
    web   = "10.10.3.0/24"
    db    = "10.10.4.0/24"
  }
}



output "subnet_ids" {
  value = {
    proxy = module.proxy_subnet.subnet_id
    api   = module.api_subnet.subnet_id
    web   = module.web_subnet.subnet_id
    db    = module.db_subnet.subnet_id
  }
}

output "nsg_ids" {
  value = {
    proxy = module.proxy_subnet.nsg_id
    api   = module.api_subnet.nsg_id
    web   = module.web_subnet.nsg_id
    db    = module.db_subnet.nsg_id
  }
}



variable "backend_sa" { default = "tfstate-hub-99676" }
variable "env_name"    { default = "hub" }
variable "resource_group" { default = "rg-hub" }
variable "location"    { default = "eastus2" }
variable "vnet_cidr"    { default = "10.0.0.0/16" }
variable "subnets"    {
  default = {
    jump          = "10.0.1.0/24"
    cicd          = "10.0.2.0/24"
    observability = "10.0.3.0/24"
    metrics       = "10.0.4.0/24"
    logs          = "10.0.5.0/24"
    trace         = "10.0.6.0/24"
  }
}
variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}


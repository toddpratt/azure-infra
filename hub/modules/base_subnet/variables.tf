
variable "rg_name" { type = string }
variable "location" { type = string }
variable "vnet_name" { type = string }
variable "name_prefix" { type = string }
variable "subnet" { type = string }
variable "public_ssh" {
  type = bool
  default = false
}
variable "jumphost_subnet" {
  type = string
  default = null
}


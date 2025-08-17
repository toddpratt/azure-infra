
variable "rg_name" { type = string }
variable "location" { type = string }
variable "vnet_name" { type = string }
variable "name_prefix" { type = string }
variable "subnet" { type = string }
variable "public_ssh" {
  type = bool
  default = false
}
variable "metrics_subnet" {
  type = string
}
variable "jumphost_subnet" {
  type = string
  default = null
}
#
# the list will look like:
# [
#   {
#     port_range = "80-8080"
#     source_ip  = "*"
#
variable "allow_rules" {
  type = list(map(string))
  default = []
}



variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "name_prefix"         { type = string }
variable "vnet_cidr"           { type = string }
variable "subnets"             { type = map(string) }
variable "peer_to_vnet_id" {
  type        = string
  default     = null
}
variable "peer_to_vnet_name" {
  type        = string
  default     = null
}
variable "peer_network_rg" {
  type        = string
  default     = null
}
variable "jump_subnet" { type = string }
variable "metrics_subnet" { type = string }

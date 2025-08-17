
variable "location" {
  default = "eastus"
}

variable "environments" {
  type    = list(string)
  default = ["hub", "dev", "staging", "prod"]
}


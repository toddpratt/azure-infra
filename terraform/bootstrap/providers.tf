
terraform {
  backend "local" {} # bootstrap uses local state only
}

provider "azurerm" {
  features {}
}


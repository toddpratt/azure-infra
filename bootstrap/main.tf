
resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate"
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  for_each                 = toset(var.environments)
  name                     = "tfstate${each.key}${random_integer.suffix[each.key].result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  for_each             = toset(var.environments)
  name                 = "tfstate"
  storage_account_id   = azurerm_storage_account.tfstate[each.key].id
  container_access_type = "private"
}

resource "random_integer" "suffix" {
  for_each = toset(var.environments)
  min      = 10000
  max      = 99999
}


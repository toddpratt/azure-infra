
output "tfstate_storage_accounts" {
  description = "Mapping of environment to storage account name"
  value = {
    for env, sa in azurerm_storage_account.tfstate :
    env => sa.name
  }
}


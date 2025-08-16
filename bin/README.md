# Azure Terraform State Bootstrap & Teardown Scripts

This folder contains four helper scripts for creating and removing Azure resources used to store Terraform state securely. All other resources should be created by terraform.

WARNING: These are potentially dangerous.

## Scripts

The scripts all share a sops-encrypted config file called config.env.enc that can be edited with the sops command. Make sure the config has a good random SA_PREFIX setting (openssl rand -hex 5).

1. bootstrap-tfstate - creates the resource group for the terraform state (Just once)
1. bootstrap-env-tfstate - creates an environment-specific storage account and container (Once per environment)
1. destroy-env-tfstate - deletes environment-specific storage account and container (Once per environment)
1. destroy-tfstate - deletes the resource group (Just once)


terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend"
    storage_account_name = "tfstateacct001"
    container_name       = "tfstate"
    key                  = "preprod.tfstate"
  }
}

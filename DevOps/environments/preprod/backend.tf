terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend"
    storage_account_name = "tfstatubs2026"
    container_name       = "tfstate"
    key                  = "preprod.tfstate"
  }
}

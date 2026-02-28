terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "storage_account" {
  source              = "../../terraform/azure_storage_account"
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  account_tier        = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  
  tags = merge(
    var.tags,
    { environment = "preprod" }
  )
}

module "aks" {
  source              = "../../terraform/aks"
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.aks_dns_prefix
  
  default_node_pool_vm_size = var.node_pool_vm_size
  default_node_pool_count   = var.node_pool_count
  enable_auto_scaling       = var.enable_auto_scaling
  min_count                 = var.min_node_count
  max_count                 = var.max_node_count
  
  tags = merge(
    var.tags,
    { environment = "preprod" }
  )
}

# Bootstrap backend setup (run this first to create state storage)
# This creates a storage account to hold Terraform state files
# Run once, then use for all environments

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "client_id" {
  description = "Service principal client ID"
  type        = string
}

variable "client_secret" {
  description = "Service principal client secret"
  type        = string
}

# Storage account for Terraform state
resource "azurerm_resource_group" "backend" {
  name     = "rg-terraform-backend"
  location = "eastus"

  tags = {
    purpose = "terraform-state"
    managed_by = "terraform"
  }
}

resource "azurerm_storage_account" "backend" {
  name                     = "tfstateacct001"
  resource_group_name      = azurerm_resource_group.backend.name
  location                 = azurerm_resource_group.backend.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  https_traffic_only_enabled = true

  tags = {
    purpose = "terraform-state"
    managed_by = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Container for state files
resource "azurerm_storage_container" "backend" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.backend.name
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

output "storage_account_name" {
  description = "Storage account name for backend"
  value       = azurerm_storage_account.backend.name
}

output "container_name" {
  description = "Container name for state files"
  value       = azurerm_storage_container.backend.name
}

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.backend.id
}

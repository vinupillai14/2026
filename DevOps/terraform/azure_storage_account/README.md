# Azure Storage Account Terraform Module

Simple module that creates an Azure Storage Account.

Usage example:

```hcl
module "storage" {
  source              = "./DevOps/terraform/azure_storage_account"
  name                = "mystorageacct001"
  resource_group_name = "rg-example"
  location            = "eastus"
  account_tier        = "Standard"
  account_replication_type = "LRS"
  tags = {
    env = "dev"
  }
}

output "connection_string" {
  value = module.storage.primary_connection_string
}
```

Notes:
- Ensure the `name` follows Azure rules: 3-24 lowercase letters and numbers.
- The module expects the `azurerm` provider to be configured by the caller.

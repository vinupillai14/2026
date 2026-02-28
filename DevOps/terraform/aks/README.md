# Azure Kubernetes Service (AKS) Terraform Module

This module creates a managed Azure Kubernetes Service (AKS) cluster with configurable node pools and networking.

## Usage

```hcl
module "aks" {
  source              = "./DevOps/terraform/aks"
  name                = "my-aks-cluster"
  location            = "eastus"
  resource_group_name = "rg-example"
  dns_prefix          = "myaks"
  
  default_node_pool_vm_size = "Standard_D2_v3"
  default_node_pool_count   = 3
  
  client_id     = var.azure_client_id
  client_secret = var.azure_client_secret
  
  tags = {
    env = "dev"
  }
}
```

## Module Features

- Configurable default node pool
- Support for multiple additional node pools
- Auto-scaling support
- Network policy configuration (Azure or Calico)
- Service principal authentication
- Availability zones support
- HTTP application routing (optional)

## Requirements

- Azure subscription with appropriate permissions
- Terraform >= 1.0
- AzureRM provider >= 3.0
- Authentication: Azure CLI (`az login`) or OIDC for CI/CD (see [DevOps/AUTH.md](../../AUTH.md))

## Notes

- Ensure the AKS cluster name is globally unique
- Adjust `availability_zones` based on your target region
- Default node pool uses auto-scaling (min 2, max 5 nodes by default)
- Authentication is handled by Azure CLI or OIDC (no credentials needed in code)

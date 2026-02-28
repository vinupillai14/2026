# Environment Configurations

This directory contains Terraform configurations for different deployment environments.

## Structure

```
environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── preprod/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars
```

## Environments

### Dev Environment

Located in `dev/` directory. Configuration details:
- **Storage Account**: Standard-LRS (cost-optimized)
- **AKS Cluster**: 
  - VM Size: Standard_D2_v3
  - Initial Nodes: 2
  - Auto-scaling: 2-4 nodes
- **Resource Group**: `rg-dev-2026`

### Preprod Environment

Located in `preprod/` directory. Configuration details:
- **Storage Account**: Standard-GRS (geo-redundant for higher availability)
- **AKS Cluster**:
  - VM Size: Standard_D4_v3 (more powerful)
  - Initial Nodes: 3
  - Auto-scaling: 3-8 nodes
- **Resource Group**: `rg-preprod-2026`

## Usage

Each environment is self-contained and can be deployed independently.

### Deploy Dev Environment

```bash
cd environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Deploy Preprod Environment

```bash
cd environments/preprod
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Required Environment Variables

No environment variables required! Authentication is handled by Azure CLI.

### Setup Azure CLI Authentication

```bash
az login
az account set --subscription <your-subscription-id>
```

For other authentication methods (OIDC for CI/CD, managed identity, etc.), see [DevOps/AUTH.md](../AUTH.md).

## Customization

Each environment's `terraform.tfvars` file contains environment-specific values. Modify them as needed:

- `location`: Azure region
- `resource_group_name`: Resource group name
- `storage_account_name`: Must be globally unique and follow Azure naming rules
- `aks_cluster_name`: AKS cluster name
- `node_pool_count`: Initial number of nodes
- `enable_auto_scaling`: Enable/disable autoscaling
- `min_node_count`: Minimum nodes (when autoscaling enabled)
- `max_node_count`: Maximum nodes (when autoscaling enabled)

## Modules Used

Both environments use the following Terraform modules:
- `../../terraform/azure_storage_account` - Storage account module
- `../../terraform/aks` - AKS cluster module

For more details on module variables, see the respective module README files.

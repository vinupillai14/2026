# Dev Environment Configuration

location            = "eastus"
resource_group_name = "rg-dev-2026"

# Storage Account
storage_account_name      = "stgdevacct001"
storage_account_tier      = "Standard"
storage_replication_type  = "LRS"

# AKS Cluster
aks_cluster_name = "aks-dev-2026"
aks_dns_prefix   = "aksdev2026"

# Node Pool Configuration
node_pool_vm_size = "Standard_D2_v3"
node_pool_count   = 2

# Auto-scaling
enable_auto_scaling = true
min_node_count      = 2
max_node_count      = 4

# Tags
tags = {
  project     = "2026"
  environment = "dev"
  managed_by  = "terraform"
  team        = "devops"
}

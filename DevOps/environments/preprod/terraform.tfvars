# Preprod Environment Configuration

location            = "eastus"
resource_group_name = "rg-preprod-2026"

# Storage Account
storage_account_name      = "stgpreprodacct001"
storage_account_tier      = "Standard"
storage_replication_type  = "GRS"

# AKS Cluster
aks_cluster_name = "aks-preprod-2026"
aks_dns_prefix   = "akspreprod2026"

# Node Pool Configuration
node_pool_vm_size = "Standard_D4_v3"
node_pool_count   = 3

# Auto-scaling
enable_auto_scaling = true
min_node_count      = 3
max_node_count      = 8

# Tags
tags = {
  project     = "2026"
  environment = "preprod"
  managed_by  = "terraform"
  team        = "devops"
}

location            = "eastus"
resource_group_name = "rg-dev-2026"

storage_account_name     = "stgdevacct001"
storage_account_tier     = "Standard"
storage_replication_type = "LRS"

aks_cluster_name = "aks-dev-2026"
aks_dns_prefix   = "aksdev2026"

node_pool_vm_size = "Standard_D2_v3"
node_pool_count   = 2

enable_auto_scaling = true
min_node_count      = 2
max_node_count      = 4

tags = {
  project     = "2026"
  environment = "dev"
  managed_by  = "terraform"
  team        = "devops"
}

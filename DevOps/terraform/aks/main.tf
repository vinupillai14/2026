resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  tags                = var.tags

  default_node_pool {
    name                = var.default_node_pool_name
    enable_auto_scaling = var.enable_auto_scaling
    node_count          = var.enable_auto_scaling ? null : var.default_node_pool_count
    vm_size             = var.default_node_pool_vm_size
    zones               = var.availability_zones
    max_pods            = var.max_pods
    os_disk_size_gb     = var.os_disk_size_gb
    min_count           = var.enable_auto_scaling ? var.min_count : null
    max_count           = var.enable_auto_scaling ? var.max_count : null
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    network_plugin = var.network_plugin
    network_policy = var.network_policy
    dns_service_ip = var.dns_service_ip
    service_cidr   = var.service_cidr
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  count                 = length(var.additional_node_pools)
  name                  = var.additional_node_pools[count.index].name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  node_count            = var.additional_node_pools[count.index].enable_auto_scaling ? null : var.additional_node_pools[count.index].node_count
  vm_size               = var.additional_node_pools[count.index].vm_size
  zones                 = var.availability_zones
  max_pods              = var.max_pods
  os_disk_size_gb       = var.os_disk_size_gb
  tags                  = var.tags
  min_count             = var.additional_node_pools[count.index].enable_auto_scaling ? var.additional_node_pools[count.index].min_count : null
  max_count             = var.additional_node_pools[count.index].enable_auto_scaling ? var.additional_node_pools[count.index].max_count : null
}

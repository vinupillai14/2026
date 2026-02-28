resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name                = var.default_node_pool_name
    node_count          = var.default_node_pool_count
    vm_size             = var.default_node_pool_vm_size
    availability_zones  = var.availability_zones
    max_pods            = var.max_pods
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.min_count
    max_count           = var.max_count
    os_disk_size_gb     = var.os_disk_size_gb
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    dns_service_ip    = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    service_cidr      = var.service_cidr
  }

  addon_profile {
    http_application_routing {
      enabled = var.enable_http_application_routing
    }

    kube_dashboard {
      enabled = var.enable_kube_dashboard
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  count                 = length(var.additional_node_pools)
  name                  = var.additional_node_pools[count.index].name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  node_count            = var.additional_node_pools[count.index].node_count
  vm_size               = var.additional_node_pools[count.index].vm_size
  availability_zones    = var.availability_zones
  max_pods              = var.max_pods
  enable_auto_scaling   = var.additional_node_pools[count.index].enable_auto_scaling
  min_count             = var.additional_node_pools[count.index].min_count
  max_count             = var.additional_node_pools[count.index].max_count
  os_disk_size_gb       = var.os_disk_size_gb
  tags                  = var.tags
}

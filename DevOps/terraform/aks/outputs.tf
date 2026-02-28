output "id" {
  description = "AKS cluster resource ID"
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_admin_config_raw" {
  description = "Raw kubeconfig"
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Kubeconfig object"
  value       = azurerm_kubernetes_cluster.this.kube_admin_config
  sensitive   = true
}

output "kubelet_identity" {
  description = "Kubelet identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity
}

output "node_resource_group" {
  description = "Auto-created resource group for AKS nodes"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "storage_account_id" {
  description = "Storage account resource ID"
  value       = module.storage_account.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage_account.name
}

output "storage_primary_blob_endpoint" {
  description = "Storage account primary blob endpoint"
  value       = module.storage_account.primary_blob_endpoint
}

output "aks_cluster_id" {
  description = "AKS cluster resource ID"
  value       = module.aks.id
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.name
}

output "aks_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.fqdn
}

output "aks_node_resource_group" {
  description = "AKS node resource group"
  value       = module.aks.node_resource_group
}

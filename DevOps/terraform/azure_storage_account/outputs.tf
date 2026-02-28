output "id" {
  description = "Storage account resource id"
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Storage account name"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.this.primary_connection_string
}

output "primary_access_key" {
  description = "Primary account key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

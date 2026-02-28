variable "name" {
  description = "Storage account name (3-24 lowercase alphanumeric)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "eastus"
}

variable "account_tier" {
  description = "The tier of the storage account. Options: Standard, Premium"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "The replication type for the storage account. e.g. LRS, GRS"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "The Kind of storage account (StorageV2, BlobStorage, etc.)"
  type        = string
  default     = "StorageV2"
}

variable "enable_https_traffic_only" {
  description = "Force HTTPS for storage account"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "enable_network_rules" {
  description = "Whether to configure network rules block"
  type        = bool
  default     = false
}

variable "network_default_action" {
  description = "Default action for network rules (Allow or Deny)"
  type        = string
  default     = "Deny"
}

variable "ip_rules" {
  description = "List of allowed IPs for network rules"
  type        = list(string)
  default     = []
}

variable "virtual_network_subnet_ids" {
  description = "List of subnet IDs to allow"
  type        = list(string)
  default     = []
}

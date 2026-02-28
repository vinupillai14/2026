variable "name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use (empty = latest)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "agentpool"
}

variable "default_node_pool_count" {
  description = "Number of nodes in default pool"
  type        = number
  default     = 3
}

variable "default_node_pool_vm_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "max_pods" {
  description = "Max pods per node"
  type        = number
  default     = 30
}

variable "enable_auto_scaling" {
  description = "Enable autoscaling for default node pool"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "Minimum number of nodes when autoscaling enabled"
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Maximum number of nodes when autoscaling enabled"
  type        = number
  default     = 5
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "network_plugin" {
  description = "Network plugin (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy (azure or calico)"
  type        = string
  default     = "azure"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.0.0.10"
}

variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  type        = string
  default     = "172.17.0.1/16"
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_http_application_routing" {
  description = "Enable HTTP application routing"
  type        = bool
  default     = false
}

variable "enable_kube_dashboard" {
  description = "Enable Kubernetes dashboard"
  type        = bool
  default     = false
}

variable "client_id" {
  description = "Service principal client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Service principal client secret"
  type        = string
  sensitive   = true
}

variable "additional_node_pools" {
  description = "List of additional node pools to create"
  type = list(object({
    name                = string
    node_count          = number
    vm_size             = string
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
  }))
  default = []
}

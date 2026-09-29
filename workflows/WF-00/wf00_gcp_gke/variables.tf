variable "project_id" {
  description = "Target project ID where GKE is created."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-east1"
}

variable "enable_gke" {
  description = "If false, create no GKE resources."
  type        = bool
  default     = true
}

variable "gke_location" {
  description = "Cluster location. Use a region for regional clusters (example: us-east1) or a zone for zonal clusters (example: us-east1-b)."
  type        = string
}

variable "gke_cluster_name" {
  description = "Optional. If empty, auto-named from project_id."
  type        = string
  default     = ""
}

variable "gke_node_count" {
  description = "Number of nodes in the node pool."
  type        = number
  default     = 2
}

variable "gke_machine_type" {
  description = "Node machine type (example: e2-medium)."
  type        = string
  default     = "e2-medium"
}

variable "gke_disk_size_gb" {
  description = "Node boot disk size in GB."
  type        = number
  default     = 50
}

variable "gke_release_channel" {
  description = "Optional. Release channel: RAPID, REGULAR, STABLE."
  type        = string
  default     = "REGULAR"
}

variable "network_self_link" {
  description = "VPC self link from the Network component."
  type        = string
}

variable "subnet_self_link" {
  description = "Subnet self link from the Network component."
  type        = string
}

variable "gke_name_suffix" {
  description = "Optional unique suffix for this GKE environment, for example 00, 01, or 02."
  type        = string
  default     = ""
}

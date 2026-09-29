variable "project_id" {
  description = "Target project ID where the VMs are created."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-east1"
}

variable "enable_vms" {
  description = "If false, create no VMs."
  type        = bool
  default     = true
}

variable "vm_count" {
  description = "Number of VMs to create."
  type        = number
  default     = 2
}

variable "vm_zone" {
  description = "Zone for the VMs (example: us-east1-b)."
  type        = string
}

variable "vm_machine_type" {
  description = "Machine type (example: e2-medium)."
  type        = string
  default     = "e2-medium"
}

variable "vm_image" {
  description = "Boot disk image in the form <project>/<family-or-image> (example: debian-cloud/debian-12)."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 30
}

variable "vm_tags" {
  description = "Network tags applied to instances (used for firewall targeting if desired)."
  type        = list(string)
  default     = []
}

variable "subnet_self_link" {
  description = "Subnet self link from the Network component output."
  type        = string
}

variable "enable_public_ip" {
  description = "If true, each VM gets a public IPv4 address."
  type        = bool
  default     = false
}

variable "vm_name_suffix" {
  description = "Optional unique suffix for this VM environment, for example 00, 01, or 02."
  type        = string
  default     = ""
}

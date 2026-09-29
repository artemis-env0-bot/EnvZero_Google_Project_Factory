variable "project_id" {
  description = "Target project ID where the PD is created."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-east1"
}

variable "enable_pd" {
  description = "If false, create no persistent disk."
  type        = bool
  default     = true
}

variable "pd_zone" {
  description = "Zone for the persistent disk. If empty, defaults to vm_zone."
  type        = string
  default     = ""
}

variable "pd_type" {
  description = "Disk type: pd-standard, pd-balanced, pd-ssd."
  type        = string
  default     = "pd-balanced"
}

variable "pd_size_gb" {
  description = "Disk size in GB."
  type        = number
  default     = 50
}

variable "attach_pd_to_vm" {
  description = "If true, attach the PD to a VM instance."
  type        = bool
  default     = true
}

# Recommended: map this directly from the Virtual Machine component output primary_vm_name
variable "primary_vm_name" {
  description = "Primary VM instance name to attach to. If set, it is used for attachment."
  type        = string
  default     = ""
}

# Optional: if you want index-based attachment, pass the full list of VM names and an index
variable "vm_instance_names" {
  description = "List of VM instance names. Used only when primary_vm_name is empty."
  type        = list(string)
  default     = []
}

variable "attach_pd_vm_index" {
  description = "VM index in vm_instance_names to attach to when primary_vm_name is empty."
  type        = number
  default     = 0
}

variable "vm_zone" {
  description = "Zone where the VM lives (must match pd zone for attachment). If empty, pd_zone must be set explicitly."
  type        = string
  default     = ""
}

variable "device_name" {
  description = "Optional device name for the attached disk."
  type        = string
  default     = "env0-pd"
}

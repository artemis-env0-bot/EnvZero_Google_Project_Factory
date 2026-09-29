variable "project_id" {
  description = "Target project ID where the network is created."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-east1"
}

variable "network_name" {
  description = "Optional. VPC name. If empty, it is auto-named."
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Optional. Subnet name. If empty, it is auto-named."
  type        = string
  default     = ""
}

variable "subnet_region" {
  description = "Optional. Region for subnet. If empty, defaults to region."
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "Subnet CIDR range (example: 10.10.0.0/16)."
  type        = string
}

variable "allow_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to instances (tcp/22). Empty disables the SSH firewall rule."
  type        = list(string)
  default     = []
}

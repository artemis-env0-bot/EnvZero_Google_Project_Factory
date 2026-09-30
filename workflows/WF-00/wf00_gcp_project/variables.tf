variable "bootstrap_project_id" {
  description = "Bootstrap project used for provider context and lookups."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-east1"
}

variable "org_id" {
  description = "Organization ID. Leave empty when using folder_id."
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Folder ID numeric string."
  type        = string
  default     = ""

  validation {
    condition     = trimspace(var.folder_id) != "621599609930"
    error_message = "WF-00 must not deploy into system-gsuite folder 621599609930. Use env0-demo-sandbox folder 696328868243."
  }
}

variable "project_name_prefix" {
  description = "Prefix used for the generated GCP project ID and project name."
  type        = string
  default     = "env0-demo"
}

variable "project_generation" {
  description = "Generation value used to force creation of a new globally unique project ID."
  type        = string
  default     = "1"
}

variable "existing_project_id" {
  description = "Compatibility input. WF-00 always creates its own project."
  type        = string
  default     = ""
}

variable "deletion_policy" {
  description = "Compatibility input. WF-00 enforces DELETE in main.tf."
  type        = string
  default     = "DELETE"
}

variable "caller_sa_email" {
  description = "Optional env0 runner service account email."
  type        = string
  default     = ""
}

variable "deployer_user_email" {
  description = "Optional human deployer email."
  type        = string
  default     = ""
}

variable "activate_apis" {
  description = "Google APIs enabled on the WF-00 project."
  type        = list(string)

  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

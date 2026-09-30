variable "bootstrap_project_id" {
  description = "Bootstrap project used for provider context and lookups."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID, for example 000000-000000-000000."
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
  description = "Folder ID numeric string. WF-00 should use the dedicated env0 demo sandbox folder."
  type        = string
  default     = ""

  validation {
    condition     = trimspace(var.folder_id) != "621599609930"
    error_message = "WF-00 must not deploy into system-gsuite folder 621599609930. Use the dedicated env0-demo-sandbox folder 696328868243."
  }
}

variable "project_name_prefix" {
  description = "Prefix used as the project display name and as the base for project_id when random_project_id is enabled."
  type        = string
  default     = "env0-demo"
}

variable "existing_project_id" {
  description = "Compatibility input retained for existing env0 variable sets. WF-00 always creates and manages its own project, so this value is intentionally ignored."
  type        = string
  default     = ""
}

variable "caller_sa_email" {
  description = "Optional env0 runner service account email. If empty, the caller identity is derived from google_client_openid_userinfo."
  type        = string
  default     = ""
}

variable "deployer_user_email" {
  description = "Optional human deployer email. If set, grants editor on the workflow project."
  type        = string
  default     = ""
}

variable "deletion_policy" {
  description = "Compatibility input retained for existing env0 configuration. WF-00 intentionally enforces DELETE in main.tf because the workflow owns disposable sandbox projects."
  type        = string
  default     = "DELETE"
}

variable "activate_apis" {
  description = "APIs enabled on the project managed by WF-00."
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

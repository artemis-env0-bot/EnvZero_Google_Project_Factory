variable "bootstrap_project_id" {
  description = "Bootstrap project used for provider context and lookups."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID, for example 000000-000000-000000."
  type        = string

  validation {
    condition     = trimspace(var.billing_account) != ""
    error_message = "billing_account must not be empty."
  }
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
  description = "Folder ID numeric string. WF-00 should deploy into the dedicated env0 demo sandbox folder."
  type        = string
  default     = ""

  validation {
    condition     = trimspace(var.folder_id) != "621599609930"
    error_message = "WF-00 must not deploy into system-gsuite folder 621599609930. Use env0-demo-sandbox folder 696328868243."
  }
}

variable "project_name_prefix" {
  description = "Prefix used as the project display name and as the base for the generated project ID."
  type        = string
  default     = "env0-demo"
}

################################################################################
# Compatibility inputs
################################################################################

variable "existing_project_id" {
  description = "Compatibility input retained for existing env0 variable sets. WF-00 always creates and manages its own project, so this value is intentionally ignored."
  type        = string
  default     = ""
}

variable "deletion_policy" {
  description = "Compatibility input retained for existing env0 configuration. WF-00 enforces DELETE directly in main.tf."
  type        = string
  default     = "DELETE"
}

################################################################################
# IAM
################################################################################

variable "caller_sa_email" {
  description = "Optional env0 runner service account email. If empty, the authenticated caller identity is used."
  type        = string
  default     = ""
}

variable "deployer_user_email" {
  description = "Optional human deployer email. If set, the user receives roles/editor on the created project."
  type        = string
  default     = ""
}

################################################################################
# Google APIs
################################################################################

variable "activate_apis" {
  description = "Google APIs enabled on the project created by WF-00."
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

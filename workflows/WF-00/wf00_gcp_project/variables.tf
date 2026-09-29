variable "bootstrap_project_id" {
  description = "Bootstrap project used for provider context and lookups."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID (e.g., 000000-000000-000000)."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-east1"
}

variable "org_id" {
  description = "Organization ID. Leave empty if using folder_id."
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Folder ID numeric string, for example 621599609930. Leave empty if using org_id."
  type        = string
  default     = ""
}

variable "project_name_prefix" {
  description = "Prefix used as the project display name and as the base for project_id when random_project_id is enabled."
  type        = string
  default     = "env0-demo"
}

variable "existing_project_id" {
  description = "If set, adopt this existing project ID instead of creating a new project."
  type        = string
  default     = ""
}

variable "caller_sa_email" {
  description = "Optional. env0 runner service account email. If empty, we derive the caller identity from google_client_openid_userinfo."
  type        = string
  default     = ""
}

variable "deployer_user_email" {
  description = "Optional. Human deployer email. If set, grants editor on the project so the deployer can delete created resources."
  type        = string
  default     = ""
}

variable "deletion_policy" {
  description = "Project deletion policy for projects created by GPF. Typical values are DELETE or PREVENT."
  type        = string
  default     = "DELETE"
}

variable "activate_apis" {
  description = "APIs enabled on the target project. In create mode GPF enables these. In adopt mode we enable them via google_project_service."
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

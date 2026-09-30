variable "project_id" {
  description = "Target project ID where the bucket is created."
  type        = string
}

variable "project_number" {
  description = "Target GCP project number used to generate a globally unique bucket name."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-east1"
}

variable "bucket_location" {
  description = "Cloud Storage bucket location."
  type        = string
  default     = "US"
}

variable "bucket_name_prefix" {
  description = "Optional prefix for the bucket name. If empty, project_id is used."
  type        = string
  default     = ""
}

variable "bucket_name_suffix" {
  description = "Optional suffix for the bucket name."
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Compatibility input retained for existing env0 configuration. WF-00 generates the bucket name."
  type        = string
  default     = ""
}

variable "bucket_generation" {
  description = "Generation value used to rotate the generated bucket name."
  type        = string
  default     = "1"
}

variable "force_destroy" {
  description = "If true, delete all objects when destroying the bucket."
  type        = bool
  default     = true
}

variable "deployer_user_email" {
  description = "Optional user email to grant bucket admin access."
  type        = string
  default     = ""
}

variable "enable_bucket" {
  description = "If false, create no bucket resources."
  type        = bool
  default     = true
}

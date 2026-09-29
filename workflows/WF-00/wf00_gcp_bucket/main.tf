locals {
  raw_bucket_name_prefix = var.bucket_name_prefix != "" ? var.bucket_name_prefix : "${var.project_id}-bkt"
  raw_bucket_name_suffix = var.bucket_name_suffix != "" ? var.bucket_name_suffix : "large"

  # replace() with /pattern/ syntax is regex-aware and version-agnostic
  sanitized_bucket_name_prefix = replace(lower(local.raw_bucket_name_prefix), "/[^a-z0-9-]/", "-")
  sanitized_bucket_name_suffix = replace(lower(local.raw_bucket_name_suffix), "/[^a-z0-9-]/", "-")

  bucket_name_prefix_limited = substr(
    local.sanitized_bucket_name_prefix,
    0,
    min(length(local.sanitized_bucket_name_prefix), 38)
  )

  bucket_name_suffix_limited = substr(
    local.sanitized_bucket_name_suffix,
    0,
    min(length(local.sanitized_bucket_name_suffix), 8)
  )

  deployer_member = trimspace(var.deployer_user_email) != "" ? "user:${trimspace(var.deployer_user_email)}" : ""
}

resource "random_id" "suffix" {
  count       = var.enable_bucket && var.bucket_name == "" ? 1 : 0
  byte_length = 8
}

resource "google_storage_bucket" "bucket" {
  count = var.enable_bucket ? 1 : 0

  name = var.bucket_name != "" ? var.bucket_name : "${local.bucket_name_prefix_limited}-${local.bucket_name_suffix_limited}-${random_id.suffix[0].hex}"

  project                     = var.project_id
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  lifecycle_rule {
    condition {
      age = 30
    }

    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "deployer_bucket_admin" {
  count = var.enable_bucket && local.deployer_member != "" ? 1 : 0

  bucket = google_storage_bucket.bucket[0].name
  role   = "roles/storage.admin"
  member = local.deployer_member
}

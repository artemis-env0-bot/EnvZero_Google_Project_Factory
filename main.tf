################################################################################
# main.tf: Create NEW project via GPF or ADOPT existing,
# then create a test bucket (and optional PD).
# Uses local.effective_project_id everywhere so it works for both flows.
################################################################################

# Who am I? (for debugging)
data "google_client_openid_userinfo" "me" {}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Authenticated principal email from GOOGLE_CREDENTIALS."
}

################################################################################
# Decide: create new vs adopt existing
################################################################################

locals {
  creating = var.existing_project_id == ""

  # Parent (module expects null for the unused one)
  parent_org_id    = var.org_id    != "" ? var.org_id    : null
  parent_folder_id = var.folder_id != "" ? var.folder_id : null

  # Null-safe sanitize of caller SA for IAM grant (avoid null interpolation)
  caller_sa_sanitized = var.caller_sa_email != null ? var.caller_sa_email : ""
}

################################################################################
# Create (Project Factory) OR Adopt (data source)
################################################################################

# If creating, call the Project Factory module (it always creates/manages projects).
module "project_factory" {
  count   = local.creating ? 1 : 0
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  org_id    = local.parent_org_id
  folder_id = local.parent_folder_id

  # project_id is chosen in env0 pre-step to avoid collisions
  project_id        = var.project_id
  random_project_id = false

  name                    = var.project_name_prefix
  billing_account         = var.billing_account
  activate_apis           = var.activate_apis
  default_service_account = "deprivilege"
}

# If adopting, look up the existing project and enable APIs ourselves.
data "google_project" "adopted" {
  count      = local.creating ? 0 : 1
  project_id = var.existing_project_id
}

resource "google_project_service" "apis_existing" {
  count              = local.creating ? 0 : length(var.activate_apis)
  project            = data.google_project.adopted[0].project_id
  service            = var.activate_apis[count.index]
  disable_on_destroy = true
}

################################################################################
# Effective project reference (works for both paths)
################################################################################

locals {
  effective_project_id     = local.creating ? module.project_factory[0].project_id     : data.google_project.adopted[0].project_id
  effective_project_number = local.creating ? module.project_factory[0].project_number : data.google_project.adopted[0].number
}

output "created_project_id" {
  value       = local.effective_project_id
  description = "ID of the created/adopted project."
}

output "created_project_number" {
  value       = local.effective_project_number
  description = "Number of the created/adopted project."
}

################################################################################
# Optional: ensure env0 runner SA can manage the project
################################################################################

# NOTE: Renamed to avoid collision with iam_access.tf
resource "google_project_iam_member" "grant_editor_to_caller_main" {
  count   = local.caller_sa_sanitized == "" ? 0 : 1
  project = local.effective_project_id
  role    = "roles/editor"
  member  = "serviceAccount:${local.caller_sa_sanitized}"
}

################################################################################
# Test Resource A: One GCS bucket in the project
################################################################################

resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_storage_bucket" "one_bucket" {
  name                        = "${local.effective_project_id}-bkt-${random_id.suffix.hex}"
  project                     = local.effective_project_id
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    action    { type = "Delete" }
    condition { age = 30 }
  }
}

output "bucket_name" {
  value       = google_storage_bucket.one_bucket.name
  description = "Name of the bucket created in the project."
}

output "bucket_url" {
  value       = "gs://${google_storage_bucket.one_bucket.name}"
  description = "gs:// URL of the bucket."
}

################################################################################
# Test Resource B (optional): Persistent Disk
################################################################################

resource "google_compute_disk" "test_pd" {
  count   = var.enable_persistent_disk ? 1 : 0
  name    = "${local.effective_project_id}-pd-${var.disk_size_gb}g"
  project = local.effective_project_id
  zone    = var.disk_zone
  type    = var.disk_type
  size    = var.disk_size_gb
}

output "test_pd_self_link" {
  value       = try(google_compute_disk.test_pd[0].self_link, null)
  description = "Self link for the test persistent disk (only when enabled)."
}

# --------------------------------------------------------------------------------
# iam_access.tf
# Grants the deployer (human) visibility + delete capability on the created bucket
# and visibility on the project, so the project/bucket show up in the GCP UI.
# --------------------------------------------------------------------------------

# Grant deployer visibility on the PROJECT (so it appears in the Console)
resource "google_project_iam_member" "deployer_viewer" {
  count   = var.deployer_user_email != null && var.deployer_user_email != "" ? 1 : 0
  project = local.effective_project_id
  role    = "roles/viewer"
  member  = "user:${var.deployer_user_email}"
}

# Grant deployer full control over the BUCKET (so you can list/describe/delete objects + bucket)
resource "google_storage_bucket_iam_member" "deployer_bucket_admin" {
  count  = var.deployer_user_email != null && var.deployer_user_email != "" ? 1 : 0
  bucket = google_storage_bucket.one_bucket.name
  role   = "roles/storage.admin"
  member = "user:${var.deployer_user_email}"

  depends_on = [google_storage_bucket.one_bucket]
}

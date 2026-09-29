output "project_id" {
  value       = var.project_id
  description = "Project ID where the bucket was created."
}

output "bucket_name" {
  value       = try(google_storage_bucket.bucket[0].name, null)
  description = "Bucket name (null if enable_bucket=false)."
}

output "bucket_url" {
  value       = try("gs://${google_storage_bucket.bucket[0].name}", null)
  description = "Bucket URL (null if enable_bucket=false)."
}

output "bucket_location" {
  value       = try(google_storage_bucket.bucket[0].location, null)
  description = "Bucket location (null if enable_bucket=false)."
}

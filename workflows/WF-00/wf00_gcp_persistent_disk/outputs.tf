output "project_id" {
  value       = var.project_id
  description = "Project ID where the PD was created."
}

output "pd_name" {
  value       = try(google_compute_disk.pd[0].name, null)
  description = "Persistent disk name (null if enable_pd=false)."
}

output "pd_self_link" {
  value       = try(google_compute_disk.pd[0].self_link, null)
  description = "Persistent disk self link (null if enable_pd=false)."
}

output "pd_zone" {
  value       = try(google_compute_disk.pd[0].zone, null)
  description = "Zone of the persistent disk (null if enable_pd=false)."
}

output "attached_instance" {
  value       = try(google_compute_attached_disk.attach[0].instance, null)
  description = "VM instance name the disk is attached to (null if not attached)."
}

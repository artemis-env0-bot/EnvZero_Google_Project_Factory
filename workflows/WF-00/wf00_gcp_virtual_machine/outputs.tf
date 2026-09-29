output "project_id" {
  value       = var.project_id
  description = "Project ID where the VMs were created."
}

output "vm_instance_names" {
  value       = [for i in google_compute_instance.vm : i.name]
  description = "List of VM instance names."
}

output "vm_instance_self_links" {
  value       = [for i in google_compute_instance.vm : i.self_link]
  description = "List of VM self links."
}

output "primary_vm_name" {
  value       = try(google_compute_instance.vm[0].name, null)
  description = "Primary VM name (index 0), useful for PD attachment."
}

output "primary_vm_zone" {
  value       = var.vm_zone
  description = "VM zone used for the instances."
}

output "public_ips" {
  value       = [for i in google_compute_instance.vm : try(i.network_interface[0].access_config[0].nat_ip, null)]
  description = "Public IPs (null entries if enable_public_ip=false)."
}

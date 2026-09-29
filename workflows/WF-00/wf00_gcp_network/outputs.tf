output "project_id" {
  value       = var.project_id
  description = "Project ID where the network was created."
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "VPC network name."
}

output "network_self_link" {
  value       = google_compute_network.vpc.self_link
  description = "VPC self link."
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "Subnet name."
}

output "subnet_self_link" {
  value       = google_compute_subnetwork.subnet.self_link
  description = "Subnet self link."
}

output "subnet_region" {
  value       = google_compute_subnetwork.subnet.region
  description = "Subnet region."
}

output "allow_ssh_firewall_name" {
  value       = try(google_compute_firewall.allow_ssh[0].name, null)
  description = "Firewall rule name for SSH (null if SSH rule disabled)."
}

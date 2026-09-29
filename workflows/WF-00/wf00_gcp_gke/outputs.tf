output "project_id" {
  value       = var.project_id
  description = "Project ID where GKE was created."
}

output "cluster_name" {
  value       = try(google_container_cluster.cluster[0].name, null)
  description = "GKE cluster name (null if enable_gke=false)."
}

output "cluster_location" {
  value       = var.gke_location
  description = "Cluster location (region or zone)."
}

output "cluster_endpoint" {
  value       = try(google_container_cluster.cluster[0].endpoint, null)
  description = "Cluster endpoint (null if enable_gke=false)."
}

output "node_pool_name" {
  value       = try(google_container_node_pool.primary[0].name, null)
  description = "Node pool name (null if enable_gke=false)."
}

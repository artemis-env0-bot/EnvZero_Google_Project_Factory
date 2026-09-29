locals {
  effective_network_name = var.network_name != "" ? var.network_name : "${var.project_id}-vpc"
  effective_subnet_name  = var.subnet_name != "" ? var.subnet_name : "${var.project_id}-subnet"
  effective_subnet_region = var.subnet_region != "" ? var.subnet_region : var.region
}

resource "google_compute_network" "vpc" {
  name                    = local.effective_network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  name                     = local.effective_subnet_name
  region                   = local.effective_subnet_region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

# Allow internal traffic within the subnet CIDR
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_id}-fw-allow-internal"
  network = google_compute_network.vpc.name

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = [var.subnet_cidr]

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }
}

# Optional SSH ingress rule (only created when allow_ssh_cidrs is not empty)
resource "google_compute_firewall" "allow_ssh" {
  count   = length(var.allow_ssh_cidrs) > 0 ? 1 : 0
  name    = "${var.project_id}-fw-allow-ssh"
  network = google_compute_network.vpc.name

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.allow_ssh_cidrs

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

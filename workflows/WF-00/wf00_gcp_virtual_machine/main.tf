resource "random_id" "name_suffix" {
  byte_length = 4
}

locals {
  effective_count = var.enable_vms ? var.vm_count : 0

  resolved_suffix = var.vm_name_suffix != "" ? var.vm_name_suffix : random_id.name_suffix.hex
  vm_name_base    = "${var.project_id}-vm-${local.resolved_suffix}"
}

resource "google_compute_instance" "vm" {
  count = local.effective_count

  name         = var.vm_count == 1 ? local.vm_name_base : "${local.vm_name_base}-${count.index + 1}"
  machine_type = var.vm_machine_type
  zone         = var.vm_zone
  tags         = var.vm_tags

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.vm_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link

    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    "enable-oslogin" = "TRUE"
  }
}

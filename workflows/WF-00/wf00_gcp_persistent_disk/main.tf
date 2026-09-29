locals {
  effective_vm_name = (
    trimspace(var.primary_vm_name) != "" ? trimspace(var.primary_vm_name) :
    (length(var.vm_instance_names) > 0 ? var.vm_instance_names[tonumber(var.attach_pd_vm_index)] : "")
  )

  effective_zone = (
    trimspace(var.pd_zone) != "" ? trimspace(var.pd_zone) :
    (trimspace(var.vm_zone) != "" ? trimspace(var.vm_zone) : "")
  )

  should_attach = var.enable_pd && var.attach_pd_to_vm && local.effective_vm_name != "" && local.effective_zone != ""
}

resource "random_id" "suffix" {
  count       = var.enable_pd ? 1 : 0
  byte_length = 2
}

resource "google_compute_disk" "pd" {
  count   = var.enable_pd ? 1 : 0
  name    = "${var.project_id}-pd-${var.pd_size_gb}g-${random_id.suffix[0].hex}"
  project = var.project_id
  zone    = local.effective_zone != "" ? local.effective_zone : "us-east1-b"
  type    = var.pd_type
  size    = var.pd_size_gb
}

# Attach disk to VM (optional)
resource "google_compute_attached_disk" "attach" {
  count    = local.should_attach ? 1 : 0
  project  = var.project_id
  zone     = local.effective_zone
  instance = local.effective_vm_name
  disk     = google_compute_disk.pd[0].name
  device_name = var.device_name
}

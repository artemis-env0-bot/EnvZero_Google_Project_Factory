data "google_client_openid_userinfo" "me" {}

resource "random_id" "project_suffix" {
  byte_length = 4

  keepers = {
    generation = var.project_generation
  }
}

locals {
  parent_folder_id = trimspace(var.folder_id) != "" ? trimspace(var.folder_id) : null

  parent_org_id = (
    local.parent_folder_id == null && trimspace(var.org_id) != ""
    ? trimspace(var.org_id)
    : null
  )

  caller_email = trimspace(
    var.caller_sa_email != ""
    ? var.caller_sa_email
    : data.google_client_openid_userinfo.me.email
  )

  caller_is_sa = (
    local.caller_email != "" &&
    can(regex("\\.gserviceaccount\\.com$", local.caller_email))
  )

  caller_member = (
    local.caller_email == ""
    ? ""
    : (
      local.caller_is_sa
      ? "serviceAccount:${local.caller_email}"
      : "user:${local.caller_email}"
    )
  )

  deployer_email = trimspace(var.deployer_user_email)

  deployer_member = (
    local.deployer_email != ""
    ? "user:${local.deployer_email}"
    : ""
  )

  generated_project_id = "${var.project_name_prefix}-${random_id.project_suffix.hex}"
}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Identity running Terraform in env0."
}

module "project_factory" {
  count   = 1
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  org_id    = local.parent_org_id
  folder_id = local.parent_folder_id

  name              = var.project_name_prefix
  project_id        = local.generated_project_id
  random_project_id = false

  billing_account = var.billing_account
  activate_apis   = var.activate_apis

  default_service_account = "deprivilege"

  deletion_policy             = "DELETE"
  disable_services_on_destroy = false
  auto_create_network         = true
}

locals {
  project_id     = module.project_factory[0].project_id
  project_number = module.project_factory[0].project_number
}

resource "google_project_iam_member" "caller_editor" {
  count   = local.caller_member != "" ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = local.caller_member
}

resource "google_project_iam_member" "deployer_editor" {
  count   = local.deployer_member != "" ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = local.deployer_member
}

data "google_client_openid_userinfo" "me" {}

locals {
  # WF-00 owns and manages the GCP project it creates.
  #
  # This workflow intentionally does not adopt an existing project. A fresh
  # Terraform workspace must result in a fresh GCP project created directly
  # inside the configured sandbox folder.
  creating = true

  # folder_id takes precedence when supplied.
  parent_folder_id = trimspace(var.folder_id) != "" ? trimspace(var.folder_id) : null

  parent_org_id = (
    local.parent_folder_id == null && trimspace(var.org_id) != ""
    ? trimspace(var.org_id)
    : null
  )

  # Determine the identity that should receive project-level access.
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
}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Identity running OpenTofu or Terraform in env0."
}

################################################################################
# Google Project Factory
################################################################################

module "project_factory" {
  count   = 1
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  org_id    = local.parent_org_id
  folder_id = local.parent_folder_id

  name              = var.project_name_prefix
  billing_account   = var.billing_account
  random_project_id = true

  activate_apis = var.activate_apis

  default_service_account = "deprivilege"

  # WF-00 creates disposable sandbox projects.
  #
  # This is intentionally enforced here rather than depending on an env0
  # variable override. Projects created by this workflow must be deletable
  # during destroy.
  deletion_policy = "DELETE"

  # The entire project is disposable. There is no benefit in disabling each
  # service individually before deleting the project.
  disable_services_on_destroy = false
}

################################################################################
# Effective project values
################################################################################

locals {
  project_id     = module.project_factory[0].project_id
  project_number = module.project_factory[0].project_number
}

################################################################################
# IAM
################################################################################

# Give the env0 runner identity editor access inside the newly created project.
resource "google_project_iam_member" "caller_editor" {
  count   = local.caller_member != "" ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = local.caller_member
}

# Optionally give the human deployer editor access inside the new project.
resource "google_project_iam_member" "deployer_editor" {
  count   = local.deployer_member != "" ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = local.deployer_member
}

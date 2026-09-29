data "google_client_openid_userinfo" "me" {}

locals {
  creating = var.existing_project_id == ""

  # Parent selection (exactly one should be set when creating)
  parent_org_id    = var.org_id != "" ? var.org_id : null
  parent_folder_id = var.folder_id != "" ? var.folder_id : null

  # Caller identity for IAM grants
  caller_email = trimspace(var.caller_sa_email != "" ? var.caller_sa_email : data.google_client_openid_userinfo.me.email)

  caller_is_sa  = local.caller_email != "" && can(regex("\\.gserviceaccount\\.com$", local.caller_email))
  caller_member = local.caller_email == "" ? "" : (local.caller_is_sa ? "serviceAccount:${local.caller_email}" : "user:${local.caller_email}")

  deployer_email  = trimspace(var.deployer_user_email)
  deployer_member = local.deployer_email != "" ? "user:${local.deployer_email}" : ""
}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Identity running OpenTofu in env0."
}

# Create project using Google Project Factory when existing_project_id is empty
module "project_factory" {
  count   = local.creating ? 1 : 0
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  org_id    = local.parent_org_id
  folder_id = local.parent_folder_id

  name              = var.project_name_prefix
  billing_account   = var.billing_account
  random_project_id = true

  activate_apis = var.activate_apis

  default_service_account = "deprivilege"

  # Important: allow destroy to delete projects created by this component
  deletion_policy = var.deletion_policy
}

# Adopt existing project when existing_project_id is set
data "google_project" "adopted" {
  count      = local.creating ? 0 : 1
  project_id = var.existing_project_id
}

# When adopting, enable required APIs on the adopted project
resource "google_project_service" "adopted_apis" {
  count              = local.creating ? 0 : length(var.activate_apis)
  project            = data.google_project.adopted[0].project_id
  service            = var.activate_apis[count.index]
  disable_on_destroy = false
}

locals {
  project_id = local.creating ? module.project_factory[0].project_id : data.google_project.adopted[0].project_id

  # Project number output name differs for module vs data source
  project_number = local.creating ? module.project_factory[0].project_number : data.google_project.adopted[0].number
}

# Give the env0 runner identity editor on the project so subsequent components can create resources
resource "google_project_iam_member" "caller_editor" {
  count   = local.caller_member != "" ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = local.caller_member
}

# Give the deployer editor on the project so they can see and delete resources created by the workflow
resource "google_project_iam_member" "deployer_editor" {
  count   = local.deployer_member != "" ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = local.deployer_member
}

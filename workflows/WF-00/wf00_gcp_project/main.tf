data "google_client_openid_userinfo" "me" {}

locals {
  # WF-00 always owns and manages its GCP project.
  #
  # Keep the Project Factory module instantiated at count = 1 so the existing
  # Terraform state address remains:
  #
  # module.project_factory[0]
  #
  # This is important for environments that were originally created with
  # deletion_policy = PREVENT. The resource must remain managed long enough
  # for OpenTofu to update the state to deletion_policy = DELETE before any
  # future destroy operation is attempted.
  creating = true

  # Parent selection.
  #
  # folder_id takes precedence when both values are accidentally supplied.
  # The WF-00 sandbox should normally use folder:
  #
  # 696328868243
  parent_folder_id = var.folder_id != "" ? var.folder_id : null
  parent_org_id    = var.folder_id != "" ? null : (var.org_id != "" ? var.org_id : null)

  # Caller identity for IAM grants.
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
  description = "Identity running OpenTofu in env0."
}

# Create and manage the WF-00 project using Google Project Factory.
#
# count intentionally remains present and fixed at 1. Do not remove count
# from this module without performing a Terraform state migration because the
# existing resource address is module.project_factory[0].
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

  # WF-00 is a disposable sandbox workflow.
  #
  # This is intentionally hard-coded instead of consuming a variable so that
  # an organization, project, environment, or variable-set override cannot
  # accidentally restore PREVENT for this workflow.
  #
  # An existing project that has PREVENT recorded in Terraform state must
  # first complete a normal apply with this resource still present. That
  # updates the state to DELETE. A subsequent destroy can then delete it.
  deletion_policy = "DELETE"

  # There is no reason to disable individual APIs before deleting a project
  # that this workflow owns. Leaving services enabled also prevents another
  # partially dismantled project if project deletion fails for an unrelated
  # IAM or GCP issue.
  disable_services_on_destroy = false
}

locals {
  project_id     = module.project_factory[0].project_id
  project_number = module.project_factory[0].project_number
}

# Give the env0 runner identity editor on the project so subsequent
# workflow components can create resources.
resource "google_project_iam_member" "caller_editor" {
  count   = local.caller_member != "" ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = local.caller_member
}

# Give the deployer editor on the project so they can see and delete
# resources created by the workflow.
resource "google_project_iam_member" "deployer_editor" {
  count   = local.deployer_member != "" ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = local.deployer_member
}

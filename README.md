<h3 align="left">
  <img width="600" height="128" alt="image" src="https://raw.githubusercontent.com/artemis-env0/Packages/refs/heads/main/Images/Logo%20Pack/01%20Main%20Logo/Digital/SVG/envzero_logomark_fullcolor_rgb.svg" />
</h3>

---

Deploy using OpenTofu + Google Project Factory (GPF) + env0
----
## EnvZero Demo Package

This repository demonstrates a minimal env0-driven workflow that:

- Uses OpenTofu to call Google Project Factory v18
- Creates a brand new GCP project or adopts an existing one
- Deploys a single test resource (default is a GCS bucket) in the target project
- Optionally creates a Compute Persistent Disk
- Optionally grants the env0 runner service account permissions in the target project
- Grants the deployer user access so they can see and delete what was created

You can run this in env0 (recommended) or locally with OpenTofu.

---

## Prerequisites

- A bootstrap GCP project for provider auth and lookups
- A service account in the bootstrap project with a JSON key
- The JSON key stored in env0 as `GOOGLE_CREDENTIALS`
- Core APIs enabled once in the bootstrap project:
  - `cloudresourcemanager.googleapis.com`
  - `serviceusage.googleapis.com`
  - `iam.googleapis.com`
  - `cloudbilling.googleapis.com`

### Required permissions for the runner service account

On Org or Folder scope (choose one):

- `roles/resourcemanager.projectCreator`
- `roles/serviceusage.serviceUsageAdmin`
- `roles/iam.serviceAccountAdmin`
- Viewer role for that scope (`roles/resourcemanager.organizationViewer` or `roles/resourcemanager.folderViewer`)

On Billing Account:

- `roles/billing.user`

On Bootstrap Project (only if Terraform manages bootstrap APIs):

- `roles/serviceusage.serviceUsageAdmin`
- `roles/viewer`

---

## What this deploys

- A GCP project via `terraform-google-modules/project-factory/google` v18 (create flow) or adoption of an existing project (adopt flow)
- One GCS bucket in the target project
- Optional Compute Persistent Disk
- IAM bindings so the deployer can see the project in the Console and delete the bucket resources

---

## Project creation and adoption logic

The deployment follows this logic:

- If `existing_project_id` is set, the deployment adopts that project and creates resources in it
- If `existing_project_id` is empty, the deployment creates a new project using Project Factory
- In env0, inputs are validated and a consistent `env0.auto.tfvars.json` is generated before plan so plan and apply use identical values

---

## Quick start with env0

1. Connect this repo to an env0 Project and create a new Environment.
2. Configure env0 Environment Variables.

### Secrets

- `GOOGLE_CREDENTIALS` : Paste the service account JSON

### Plain variables

- `ENV0_OPENTOFU_VERSION = 1.7.0`
- `TF_VAR_bootstrap_project_id = <your-bootstrap-project-id>`
- `TF_VAR_billing_account = 000000-000000-000000`
- Exactly one of:
  - `TF_VAR_org_id = 123456789012`
  - `TF_VAR_folder_id = folders/123456789012`
- Optional:
  - `TF_VAR_project_name_prefix = env0-demo`
  - `TF_VAR_bucket_location = US`
  - `TF_VAR_region = us-central1`
  - `TF_VAR_enable_persistent_disk = false` or `true`
  - `TF_VAR_disk_zone = us-central1-a`
  - `TF_VAR_disk_type = pd-standard`
  - `TF_VAR_disk_size_gb = 10`
  - `TF_VAR_caller_sa_email = <runner SA email>`
  - `TF_VAR_deployer_user_email = <your.user@company.com>`
  - `TF_VAR_existing_project_id = <project-id-to-adopt>` (only when reusing an existing project)

3. Click Plan, then Apply.

---

## Repository file examples

This section includes full examples of every file used by this repo.

### env0.yaml

```yaml
version: 2
shell: bash

deploy:
  steps:
    setupVariables:
      after:
        - name: Print tool versions
          run: |
            set -euo pipefail
            echo "=== Tool versions ==="
            tofu version || true
            jq --version || true
            echo "ENV0_OPENTOFU_VERSION=${ENV0_OPENTOFU_VERSION:-unset}"

        - name: Who is authenticated
          run: |
            set -euo pipefail
            echo "=== Authenticated principal ==="
            if [ -n "${GOOGLE_CREDENTIALS-}" ]; then
              echo "$GOOGLE_CREDENTIALS" | jq -r '.client_email'
            elif [ -n "${GOOGLE_APPLICATION_CREDENTIALS-}" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
              jq -r '.client_email' "$GOOGLE_APPLICATION_CREDENTIALS"
            else
              gcloud auth list --filter=status:ACTIVE --format='value(account)' || true
            fi

        - name: Remove any stale tfvars
          run: |
            rm -f env0.auto.tfvars.json
            echo "Removed stale env0.auto.tfvars.json (if existed)."

        - name: Resolve inputs and write env0.auto.tfvars.json
          run: |
            set -euo pipefail

            resolve() {
              local key="$1"
              local tfvar="TF_VAR_${key}"
              if [ -n "${!tfvar-}" ]; then
                echo "${!tfvar}"
              elif [ -n "${!key-}" ]; then
                echo "${!key}"
              else
                echo ""
              fi
            }

            RES_BOOTSTRAP_PROJECT_ID="$(resolve bootstrap_project_id)"
            RES_BILLING_ACCOUNT="$(resolve billing_account)"
            RES_ORG_ID="$(resolve org_id)"
            RES_FOLDER_ID="$(resolve folder_id)"
            RES_PROJECT_NAME_PREFIX="$(resolve project_name_prefix)"
            RES_BUCKET_LOCATION="$(resolve bucket_location)"
            RES_REGION="$(resolve region)"
            RES_ENABLE_PD="$(resolve enable_persistent_disk)"
            RES_DISK_ZONE="$(resolve disk_zone)"
            RES_DISK_TYPE="$(resolve disk_type)"
            RES_DISK_SIZE_GB="$(resolve disk_size_gb)"
            RES_CALLER_SA_EMAIL="$(resolve caller_sa_email)"
            RES_DEPLOYER_USER_EMAIL="$(resolve deployer_user_email)"
            RES_EXISTING_PROJECT_ID="$(resolve existing_project_id)"

            echo "bootstrap_project_id=${RES_BOOTSTRAP_PROJECT_ID:-<missing>}"
            echo "billing_account=${RES_BILLING_ACCOUNT:-<missing>}"
            echo "org_id=${RES_ORG_ID:-<empty>}"
            echo "folder_id=${RES_FOLDER_ID:-<empty>}"
            echo "existing_project_id=${RES_EXISTING_PROJECT_ID:-<empty>}"
            echo "deployer_user_email=${RES_DEPLOYER_USER_EMAIL:-<empty>}"

            missing=0
            [ -z "${RES_BOOTSTRAP_PROJECT_ID}" ] && echo "Missing required variable: bootstrap_project_id" >&2 && missing=1
            [ -z "${RES_BILLING_ACCOUNT}" ] && echo "Missing required variable: billing_account" >&2 && missing=1

            # If we are creating a project, require exactly one of org_id or folder_id.
            if [ -z "${RES_EXISTING_PROJECT_ID}" ]; then
              count=0
              [ -n "${RES_ORG_ID}" ] && count=$((count+1))
              [ -n "${RES_FOLDER_ID}" ] && count=$((count+1))
              if [ "${count}" -ne 1 ]; then
                echo "Exactly one of org_id or folder_id must be set when existing_project_id is empty." >&2
                missing=1
              fi
            fi

            if [ "${missing}" -ne 0 ]; then
              exit 1
            fi

            # Safe defaults
            RES_PROJECT_NAME_PREFIX="${RES_PROJECT_NAME_PREFIX:-env0-demo}"
            RES_BUCKET_LOCATION="${RES_BUCKET_LOCATION:-US}"
            RES_REGION="${RES_REGION:-us-central1}"
            RES_ENABLE_PD="${RES_ENABLE_PD:-false}"
            RES_DISK_ZONE="${RES_DISK_ZONE:-us-central1-a}"
            RES_DISK_TYPE="${RES_DISK_TYPE:-pd-standard}"
            RES_DISK_SIZE_GB="${RES_DISK_SIZE_GB:-10}"

            # Normalize boolean for jq
            EPD="$(echo "${RES_ENABLE_PD}" | tr '[:upper:]' '[:lower:]')"
            if [ "${EPD}" != "true" ] && [ "${EPD}" != "false" ]; then
              EPD="false"
            fi

            jq -n \
              --arg bpid "${RES_BOOTSTRAP_PROJECT_ID}" \
              --arg ba "${RES_BILLING_ACCOUNT}" \
              --arg oid "${RES_ORG_ID}" \
              --arg fid "${RES_FOLDER_ID}" \
              --arg pfx "${RES_PROJECT_NAME_PREFIX}" \
              --arg loc "${RES_BUCKET_LOCATION}" \
              --arg reg "${RES_REGION}" \
              --arg dz "${RES_DISK_ZONE}" \
              --arg dt "${RES_DISK_TYPE}" \
              --arg dsz "${RES_DISK_SIZE_GB}" \
              --arg csa "${RES_CALLER_SA_EMAIL}" \
              --arg due "${RES_DEPLOYER_USER_EMAIL}" \
              --arg eprj "${RES_EXISTING_PROJECT_ID}" \
              --argjson epd "${EPD}" \
              '{
                bootstrap_project_id: $bpid,
                billing_account: $ba,
                org_id: (if ($oid|length) > 0 then $oid else "" end),
                folder_id: (if ($fid|length) > 0 then $fid else "" end),
                project_name_prefix: $pfx,
                bucket_location: $loc,
                region: $reg,
                enable_persistent_disk: $epd,
                disk_zone: $dz,
                disk_type: $dt,
                disk_size_gb: ($dsz|tonumber),
                caller_sa_email: (if ($csa|length) > 0 then $csa else "" end),
                deployer_user_email: (if ($due|length) > 0 then $due else "" end),
                existing_project_id: (if ($eprj|length) > 0 then $eprj else "" end)
              }' > env0.auto.tfvars.json

            echo "Wrote env0.auto.tfvars.json"

    terraformApply:
      after:
        - name: Print outputs (JSON)
          run: |
            echo "=== OpenTofu outputs (JSON) ==="
            tofu output -json || true
```

### providers.tf

```hcl
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Provider uses the existing bootstrap project (not the new one)
provider "google" {
  project = var.bootstrap_project_id
  region  = var.region
}
```

### variables.tf

```hcl
################################################################################
# Provider / bootstrap
################################################################################

variable "bootstrap_project_id" {
  description = "Existing project used by the google provider for auth/lookups."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-central1"
}

################################################################################
# Org / folder / billing
################################################################################

variable "org_id" {
  description = "Organization ID (leave empty if using folder_id)."
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Folder ID in the form 'folders/123456789012' (leave empty if using org_id)."
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "Billing account ID (e.g., 000000-000000-000000)."
  type        = string
}

################################################################################
# Create vs adopt controls
################################################################################

variable "existing_project_id" {
  description = "If non-empty, adopt this existing project and deploy resources into it."
  type        = string
  default     = ""
}

# Only used for the create flow when existing_project_id is empty.
# If you leave this empty, Project Factory can randomize the project id when random_project_id is true.
variable "project_id" {
  description = "Project ID to create when existing_project_id is empty. Leave empty to let Project Factory generate."
  type        = string
  default     = ""
}

################################################################################
# Convenience / naming
################################################################################

variable "project_name_prefix" {
  description = "Prefix for the new project's display name."
  type        = string
  default     = "env0-demo"
}

################################################################################
# APIs to enable in the target project
################################################################################

variable "activate_apis" {
  description = "APIs to enable in the target project."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com"
  ]
}

################################################################################
# Optional: grant runner SA access
################################################################################

variable "caller_sa_email" {
  description = "Service account email used by env0 (to grant project-level role). Leave empty to skip."
  type        = string
  default     = ""
}

################################################################################
# Optional: grant deployer user access so resources are visible and deletable
################################################################################

variable "deployer_user_email" {
  description = "User email to grant viewer on project and storage admin on bucket. Leave empty to skip."
  type        = string
  default     = ""
}

################################################################################
# Bucket settings
################################################################################

variable "bucket_location" {
  description = "Bucket location/region or multi-region (e.g., US, EU, us-central1)."
  type        = string
  default     = "US"
}

################################################################################
# Persistent Disk (optional)
################################################################################

variable "enable_persistent_disk" {
  description = "Set true to create a test persistent disk in the target project."
  type        = bool
  default     = false
}

variable "disk_zone" {
  description = "Zone for the test persistent disk."
  type        = string
  default     = "us-central1-a"
}

variable "disk_type" {
  description = "Disk type: pd-standard | pd-balanced | pd-ssd."
  type        = string
  default     = "pd-standard"
}

variable "disk_size_gb" {
  description = "Disk size in GB."
  type        = number
  default     = 10
}
```

### main.tf

```hcl
################################################################################
# main.tf: Create NEW project via GPF or ADOPT existing,
# then create a test bucket (and optional PD).
# Uses local.effective_project_id everywhere so it works for both flows.
################################################################################

# Who am I? (for debugging)
data "google_client_openid_userinfo" "me" {}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Authenticated principal email from GOOGLE_CREDENTIALS."
}

################################################################################
# Decide: create new vs adopt existing
################################################################################

locals {
  creating = var.existing_project_id == ""

  # Parent (module expects null for the unused one)
  parent_org_id    = var.org_id    != "" ? var.org_id    : null
  parent_folder_id = var.folder_id != "" ? var.folder_id : null

  # Null-safe sanitize of caller SA for IAM grant (avoid null interpolation)
  caller_sa_sanitized = var.caller_sa_email != null ? var.caller_sa_email : ""
}

################################################################################
# Create (Project Factory) OR Adopt (data source)
################################################################################

# If creating, call the Project Factory module.
module "project_factory" {
  count   = local.creating ? 1 : 0
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  org_id    = local.parent_org_id
  folder_id = local.parent_folder_id

  # If project_id is empty, let Project Factory randomize it (random_project_id = true).
  project_id        = var.project_id != "" ? var.project_id : null
  random_project_id = var.project_id == "" ? true : false

  name                    = var.project_name_prefix
  billing_account         = var.billing_account
  activate_apis           = var.activate_apis
  default_service_account = "deprivilege"
}

# If adopting, look up the existing project and enable APIs ourselves.
data "google_project" "adopted" {
  count      = local.creating ? 0 : 1
  project_id = var.existing_project_id
}

resource "google_project_service" "apis_existing" {
  count              = local.creating ? 0 : length(var.activate_apis)
  project            = data.google_project.adopted[0].project_id
  service            = var.activate_apis[count.index]
  disable_on_destroy = true
}

################################################################################
# Effective project reference (works for both paths)
################################################################################

locals {
  effective_project_id     = local.creating ? module.project_factory[0].project_id     : data.google_project.adopted[0].project_id
  effective_project_number = local.creating ? module.project_factory[0].project_number : data.google_project.adopted[0].number
}

output "created_project_id" {
  value       = local.effective_project_id
  description = "ID of the created or adopted project."
}

output "created_project_number" {
  value       = local.effective_project_number
  description = "Number of the created or adopted project."
}

################################################################################
# Optional: ensure env0 runner SA can manage the project
################################################################################

resource "google_project_iam_member" "grant_editor_to_caller" {
  count   = local.caller_sa_sanitized == "" ? 0 : 1
  project = local.effective_project_id
  role    = "roles/editor"
  member  = "serviceAccount:${local.caller_sa_sanitized}"
}

################################################################################
# Test Resource A: One GCS bucket in the project
################################################################################

resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_storage_bucket" "one_bucket" {
  name                        = "${local.effective_project_id}-bkt-${random_id.suffix.hex}"
  project                     = local.effective_project_id
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    action    { type = "Delete" }
    condition { age = 30 }
  }
}

output "bucket_name" {
  value       = google_storage_bucket.one_bucket.name
  description = "Name of the bucket created in the project."
}

output "bucket_url" {
  value       = "gs://${google_storage_bucket.one_bucket.name}"
  description = "gs:// URL of the bucket."
}

################################################################################
# Test Resource B (optional): Persistent Disk
################################################################################

resource "google_compute_disk" "test_pd" {
  count   = var.enable_persistent_disk ? 1 : 0
  name    = "${local.effective_project_id}-pd-${var.disk_size_gb}g"
  project = local.effective_project_id
  zone    = var.disk_zone
  type    = var.disk_type
  size    = var.disk_size_gb
}

output "test_pd_self_link" {
  value       = try(google_compute_disk.test_pd[0].self_link, null)
  description = "Self link for the test persistent disk (only when enabled)."
}
```

### iam_access.tf

```hcl
################################################################################
# iam_access.tf
# Grants the deployer (human) visibility plus bucket admin so they can verify
# and delete resources created by env0.
################################################################################

resource "google_project_iam_member" "deployer_viewer" {
  count   = var.deployer_user_email != "" ? 1 : 0
  project = local.effective_project_id
  role    = "roles/viewer"
  member  = "user:${var.deployer_user_email}"
}

resource "google_storage_bucket_iam_member" "deployer_bucket_admin" {
  count  = var.deployer_user_email != "" ? 1 : 0
  bucket = google_storage_bucket.one_bucket.name
  role   = "roles/storage.admin"
  member = "user:${var.deployer_user_email}"

  depends_on = [google_storage_bucket.one_bucket]
}
```

### outputs.tf

```hcl
# Intentionally empty.
# Outputs are defined in main.tf.
```

### .gitignore

```gitignore
# OpenTofu/Terraform local files
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Keys (never commit)
*.json
*.pem
*.p12
```

---

## Debugging

### Running locally

```bash
# 1) Set credentials (same SA used in env0)
export GOOGLE_CREDENTIALS="$(cat ./env0-gpf-admin.json)"
# or export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json

# 2) Initialize and plan
tofu init
tofu plan

# 3) Apply
tofu apply

# 4) See outputs
tofu output
```

---

## Outputs

- `whoami_email` : authenticated principal email
- `created_project_id` : ID of the created or adopted project
- `created_project_number` : numeric project ID
- `bucket_name` : created bucket name
- `bucket_url` : gs:// URL of the bucket
- `test_pd_self_link` : self link of optional Persistent Disk

---

## Common errors and fixes

### Cloud Billing API disabled

Enable Cloud Billing API in the bootstrap project:

```bash
gcloud services enable cloudbilling.googleapis.com --project <bootstrap-project-id>
```

### AUTH_PERMISSION_DENIED from serviceusage.googleapis.com

Cause: The runner service account cannot list or enable services on the project it targets.

Fix: Grant the runner service account on the bootstrap project or relevant scope:

```bash
gcloud projects add-iam-policy-binding "<bootstrap-project-id>" \
  --member="serviceAccount:<sa-email>" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding "<bootstrap-project-id>" \
  --member="serviceAccount:<sa-email>" \
  --role="roles/viewer"
```

Alternative: Remove bootstrap API management from Terraform and enable those APIs once manually.

### Project creation or billing link denied

Fix: Ensure the runner service account has:

- On Org or Folder scope:
  - `roles/resourcemanager.projectCreator`
  - `roles/serviceusage.serviceUsageAdmin`
  - `roles/iam.serviceAccountAdmin`
  - Viewer role for the scope
- On Billing Account:
  - `roles/billing.user`

### Project or bucket not visible in GCP Console

Cause: Your user account does not have viewer permissions on the created project.

Fix: Set `TF_VAR_deployer_user_email` so the deployment grants you access automatically.

---

## Cleanup

From env0, click Destroy on the environment.

This removes the bucket, optional Persistent Disk, and deletes the project if it was created by the deployment.

---

## FAQ

### Can I use OpenTofu with upstream Terraform modules?
Yes. Google Project Factory v18 works with OpenTofu in practice. Pin the Google provider to version `~> 7.0`.

### Do I need org_id?
No. You can use folder_id instead if your organization delegates project creation via folders.

### Where do I get caller_sa_email?
It is the `client_email` field in the `GOOGLE_CREDENTIALS` JSON.

### Where do I find created resources if I cannot see them?
Ensure `TF_VAR_deployer_user_email` is set so the deployment grants you viewer and bucket admin access.

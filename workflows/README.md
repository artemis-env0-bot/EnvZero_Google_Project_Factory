<h3 align="left">
  <img width="600" height="128" alt="image" src="https://raw.githubusercontent.com/artemis-env0/Packages/refs/heads/main/Images/Logo%20Pack/01%20Main%20Logo/Digital/SVG/envzero_logomark_fullcolor_rgb.svg" />
</h3>


# EnvZero Google Project Factory Workflows

## Overview

This repository contains env0 workflow driven Google Cloud deployments built with OpenTofu and Google Project Factory.

The workflows are organized under:

```text
workflows/
  WF-00/
```

Two workflow variants are documented in this README:

- `v.1.1.1` for the original WF-00 deployment
- `v.1.1.2` for the larger WF-00 deployment with multiple Virtual Machine, Persistent Disk, and GKE environments

This setup is designed to run inside an existing **env0 Project**, while creating new **GCP projects** through Google Project Factory.

## High level architecture

Each workflow is made of child templates:

- Project
- Network
- Bucket
- Virtual Machine
- Persistent Disk
- GKE

Each child template points to its own folder under `workflows/WF-00/`.

```text
EnvZero_Google_Project_Factory/
  workflows/
    WF-00/
      env0.workflow.yaml
      wf00_gcp_project/
      wf00_gcp_network/
      wf00_gcp_bucket/
      wf00_gcp_virtual_machine/
      wf00_gcp_persistent_disk/
      wf00_gcp_gke/
```

## Branch usage

### Branch `v.1.1.1`
This branch is the original workflow and child template codebase.

### Branch `v.1.1.2`
This branch contains the updated workflow definition for the larger WF-00 deployment. The workflow file in this branch can still point child environments to `revision: v.1.1.1` if the child template code has not changed.

## Template model in env0

Use two types of templates in env0:

### Child templates
These are normal Terraform or OpenTofu templates:

- `artem_simulation_gcp_project`
- `artem_simulation_gcp_network`
- `artem_simulation_gcp_bucket`
- `artem_simulation_gcp_virtual_machine`
- `artem_simulation_gcp_persistent_disk`
- `artem_simulation_gcp_gke`

For the larger isolated workflow variant, create a second set of child templates:

- `artem_simulation_gcp_project_Large`
- `artem_simulation_gcp_network_Large`
- `artem_simulation_gcp_bucket_Large`
- `artem_simulation_gcp_virtual_machine_Large`
- `artem_simulation_gcp_persistent_disk_Large`
- `artem_simulation_gcp_gke_Large`

### Workflow template
Create a separate **Workflow** template in env0 that points to:

```text
workflows/WF-00
```

That template reads:

```yaml
env0.workflow.yaml
```

## Variable set strategy

This implementation intentionally avoids Project level Variable Sets because the env0 Project already contains other environments.

Instead, attach Variable Sets directly to the child templates.

### Shared base Variable Set
The shared base Variable Set is:

```text
artem_simulation_gcp_vars
```

This set contains shared values such as:

- `GOOGLE_CREDENTIALS`
- `TF_VAR_bootstrap_project_id`
- `TF_VAR_billing_account`
- `TF_VAR_bucket_location`
- `TF_VAR_project_name_prefix`
- `TF_VAR_region`
- `TF_VAR_folder_id`
- `TF_VAR_existing_project_id`

### Component Variable Sets
Attach these as needed:

- `WF-00 Control`
- `WF-00 Network`
- `WF-00 Bucket`
- `WF-00 Virtual Machine`
- `WF-00 Persistent Disk`
- `WF-00 GKE`

## Template to Variable Set mapping

### Original child templates

```text
artem_simulation_gcp_project
  artem_simulation_gcp_vars
  WF-00 Control

artem_simulation_gcp_network
  artem_simulation_gcp_vars
  WF-00 Network

artem_simulation_gcp_bucket
  artem_simulation_gcp_vars
  WF-00 Bucket
  WF-00 Control

artem_simulation_gcp_virtual_machine
  artem_simulation_gcp_vars
  WF-00 Virtual Machine
  WF-00 Control

artem_simulation_gcp_persistent_disk
  artem_simulation_gcp_vars
  WF-00 Persistent Disk
  WF-00 Control

artem_simulation_gcp_gke
  artem_simulation_gcp_vars
  WF-00 GKE
  WF-00 Control
```

### Large workflow child templates

```text
artem_simulation_gcp_project_Large
  artem_simulation_gcp_vars
  WF-00 Control

artem_simulation_gcp_network_Large
  artem_simulation_gcp_vars
  WF-00 Network

artem_simulation_gcp_bucket_Large
  artem_simulation_gcp_vars
  WF-00 Bucket
  WF-00 Control

artem_simulation_gcp_virtual_machine_Large
  artem_simulation_gcp_vars
  WF-00 Virtual Machine
  WF-00 Control

artem_simulation_gcp_persistent_disk_Large
  artem_simulation_gcp_vars
  WF-00 Persistent Disk
  WF-00 Control

artem_simulation_gcp_gke_Large
  artem_simulation_gcp_vars
  WF-00 GKE
  WF-00 Control
```

## Runtime values that must not live in Variable Sets

These are passed through workflow Environment Outputs:

- `project_id`
- `network_self_link`
- `subnet_self_link`
- `primary_vm_name`
- `vm_zone`

These should be created on the **workflow template** as **Terraform Variables** of type **Environment Output**.

Do not create these as static values in component Variable Sets.

## Workflow file for branch `v.1.1.1`

Use this version for the original WF-00 deployment.

```yaml
settings:
  # Google Project Factory Workflow | artem@env0
  # version = v.1.1.1
  # detach keeps sub-environments if you remove them from the workflow file later
  # destroy would automatically destroy removed sub-environments on the next workflow deploy
  environmentRemovalStrategy: detach

# Artem Simulation Build - GPF Project

environments:
  wf00-project:
    name: WF-00 GCP Project
    templateName: artem_simulation_gcp_project
    revision: v.1.1.1
    workspace: wf00-gcp-project
    requiresApproval: false

# Artem Simulation Build - GPF Network

  wf00-network:
    name: WF-00 GCP Network
    templateName: artem_simulation_gcp_network
    revision: v.1.1.1
    workspace: wf00-gcp-network
    requiresApproval: false
    needs:
      - wf00-project

# Artem Simulation Build - GPF Bucket

  wf00-bucket:
    name: WF-00 GCP Bucket
    templateName: artem_simulation_gcp_bucket
    revision: v.1.1.1
    workspace: wf00-gcp-bucket
    requiresApproval: false
    needs:
      - wf00-project

# Artem Simulation Build - GPF Virtual Machine

  wf00-virtual-machine:
    name: WF-00 GCP Virtual Machine
    templateName: artem_simulation_gcp_virtual_machine
    revision: v.1.1.1
    workspace: wf00-gcp-virtual-machine
    requiresApproval: false
    needs:
      - wf00-network

# Artem Simulation Build - GPF Persistent Disk

  wf00-persistent-disk:
    name: WF-00 GCP Persistent Disk
    templateName: artem_simulation_gcp_persistent_disk
    revision: v.1.1.1
    workspace: wf00-gcp-persistent-disk
    requiresApproval: false
    needs:
      - wf00-virtual-machine

# Artem Simulation Build - GPF Kubernetes GKE Cluster

  wf00-gke:
    name: WF-00 GCP GKE
    templateName: artem_simulation_gcp_gke
    revision: v.1.1.1
    workspace: wf00-gcp-gke
    requiresApproval: false
    needs:
      - wf00-network
```

## Workflow file for branch `v.1.1.2`

Use this version for the larger WF-00 deployment.

```yaml
settings:
  # Google Project Factory Workflow | artem@env0
  # version = v.1.1.2
  ## version[sub] notes: Still pulls templates from v.1.1.1 (as these have not changed)
  # detach keeps sub-environments if you remove them from the workflow file later
  # destroy would automatically destroy removed sub-environments on the next workflow deploy
  environmentRemovalStrategy: detach

# Artem Simulation Build - GPF Project

environments:
  wf00-project:
    name: WF-00 GCP Project
    templateName: artem_simulation_gcp_project_Large
    revision: v.1.1.1
    workspace: wf00-gcp-project
    requiresApproval: false

# Artem Simulation Build - GPF Network

  wf00-network:
    name: WF-00 GCP Network
    templateName: artem_simulation_gcp_network_Large
    revision: v.1.1.1
    workspace: wf00-gcp-network
    requiresApproval: false
    needs:
      - wf00-project

# Artem Simulation Build - GPF Bucket

  wf00-bucket:
    name: WF-00 GCP Bucket
    templateName: artem_simulation_gcp_bucket_Large
    revision: v.1.1.1
    workspace: wf00-gcp-bucket
    requiresApproval: false
    needs:
      - wf00-project

# Artem Simulation Build - GPF Virtual Machine 00 with Persistent Disks

  wf00-virtual-machine-00:
    name: WF-00 GCP Virtual Machine VM00
    templateName: artem_simulation_gcp_virtual_machine_Large
    revision: v.1.1.1
    workspace: wf00-gcp-virtual-machine-00
    requiresApproval: false
    needs:
      - wf00-network

  wf00-persistent-disk-00:
    name: WF-00 GCP Persistent Disk PD00
    templateName: artem_simulation_gcp_persistent_disk_Large
    revision: v.1.1.1
    workspace: wf00-gcp-persistent-disk-00
    requiresApproval: false
    needs:
      - wf00-virtual-machine-00

  wf00-persistent-disk-01:
    name: WF-00 GCP Persistent Disk PD01
    templateName: artem_simulation_gcp_persistent_disk_Large
    revision: v.1.1.1
    workspace: wf00-gcp-persistent-disk-01
    requiresApproval: false
    needs:
      - wf00-virtual-machine-00

# Artem Simulation Build - GPF Virtual Machine 01 with Persistent Disks

  wf00-virtual-machine-01:
    name: WF-00 GCP Virtual Machine VM01
    templateName: artem_simulation_gcp_virtual_machine_Large
    revision: v.1.1.1
    workspace: wf00-gcp-virtual-machine-01
    requiresApproval: false
    needs:
      - wf00-network

  wf00-persistent-disk-02:
    name: WF-00 GCP Persistent Disk PD02
    templateName: artem_simulation_gcp_persistent_disk_Large
    revision: v.1.1.1
    workspace: wf00-gcp-persistent-disk-02
    requiresApproval: false
    needs:
      - wf00-virtual-machine-01

  wf00-persistent-disk-03:
    name: WF-00 GCP Persistent Disk PD03
    templateName: artem_simulation_gcp_persistent_disk_Large
    revision: v.1.1.1
    workspace: wf00-gcp-persistent-disk-03
    requiresApproval: false
    needs:
      - wf00-virtual-machine-01

# Artem Simulation Build - GPF Virtual Machine 02 with Persistent Disks

  wf00-virtual-machine-02:
    name: WF-00 GCP Virtual Machine VM02
    templateName: artem_simulation_gcp_virtual_machine_Large
    revision: v.1.1.1
    workspace: wf00-gcp-virtual-machine-02
    requiresApproval: false
    needs:
      - wf00-network

  wf00-persistent-disk-04:
    name: WF-00 GCP Persistent Disk PD04
    templateName: artem_simulation_gcp_persistent_disk_Large
    revision: v.1.1.1
    workspace: wf00-gcp-persistent-disk-04
    requiresApproval: false
    needs:
      - wf00-virtual-machine-02

  wf00-persistent-disk-05:
    name: WF-00 GCP Persistent Disk PD05
    templateName: artem_simulation_gcp_persistent_disk_Large
    revision: v.1.1.1
    workspace: wf00-gcp-persistent-disk-05
    requiresApproval: false
    needs:
      - wf00-virtual-machine-02

# Artem Simulation Build - GPF Kubernetes GKE Cluster 00

  wf00-gke-00:
    name: WF-00 GCP GKE Cluster 00
    templateName: artem_simulation_gcp_gke_Large
    revision: v.1.1.1
    workspace: wf00-gcp-gke-00
    requiresApproval: false
    needs:
      - wf00-network

# Artem Simulation Build - GPF Kubernetes GKE Cluster 01

  wf00-gke-01:
    name: WF-00 GCP GKE Cluster 01
    templateName: artem_simulation_gcp_gke_Large
    revision: v.1.1.1
    workspace: wf00-gcp-gke-01
    requiresApproval: false
    needs:
      - wf00-network

# Artem Simulation Build - GPF Kubernetes GKE Cluster 02

  wf00-gke-02:
    name: WF-00 GCP GKE Cluster 02
    templateName: artem_simulation_gcp_gke_Large
    revision: v.1.1.1
    workspace: wf00-gcp-gke-02
    requiresApproval: false
    needs:
      - wf00-network
```

## Workflow Environment Output mappings for `v.1.1.1`

Create these on the **workflow template** under **Variables** as **Terraform Variables** of type **Environment Output**.

### `wf00-network`

```text
project_id -> wf00-project / project_id
```

### `wf00-bucket`

```text
project_id -> wf00-project / project_id
```

### `wf00-virtual-machine`

```text
project_id -> wf00-project / project_id
subnet_self_link -> wf00-network / subnet_self_link
```

### `wf00-persistent-disk`

```text
project_id -> wf00-project / project_id
primary_vm_name -> wf00-virtual-machine / primary_vm_name
vm_zone -> wf00-virtual-machine / primary_vm_zone
```

### `wf00-gke`

```text
project_id -> wf00-project / project_id
network_self_link -> wf00-network / network_self_link
subnet_self_link -> wf00-network / subnet_self_link
```

## Workflow Environment Output mappings for `v.1.1.2`

Create these on the **large workflow template** under **Variables** as **Terraform Variables** of type **Environment Output**.

### `wf00-network`

```text
project_id -> wf00-project / project_id
```

### `wf00-bucket`

```text
project_id -> wf00-project / project_id
```

### `wf00-virtual-machine-00`

```text
project_id -> wf00-project / project_id
subnet_self_link -> wf00-network / subnet_self_link
```

### `wf00-virtual-machine-01`

```text
project_id -> wf00-project / project_id
subnet_self_link -> wf00-network / subnet_self_link
```

### `wf00-virtual-machine-02`

```text
project_id -> wf00-project / project_id
subnet_self_link -> wf00-network / subnet_self_link
```

### `wf00-persistent-disk-00`

```text
project_id -> wf00-project / project_id
primary_vm_name -> wf00-virtual-machine-00 / primary_vm_name
vm_zone -> wf00-virtual-machine-00 / primary_vm_zone
```

### `wf00-persistent-disk-01`

```text
project_id -> wf00-project / project_id
primary_vm_name -> wf00-virtual-machine-00 / primary_vm_name
vm_zone -> wf00-virtual-machine-00 / primary_vm_zone
```

### `wf00-persistent-disk-02`

```text
project_id -> wf00-project / project_id
primary_vm_name -> wf00-virtual-machine-01 / primary_vm_name
vm_zone -> wf00-virtual-machine-01 / primary_vm_zone
```

### `wf00-persistent-disk-03`

```text
project_id -> wf00-project / project_id
primary_vm_name -> wf00-virtual-machine-01 / primary_vm_name
vm_zone -> wf00-virtual-machine-01 / primary_vm_zone
```

### `wf00-persistent-disk-04`

```text
project_id -> wf00-project / project_id
primary_vm_name -> wf00-virtual-machine-02 / primary_vm_name
vm_zone -> wf00-virtual-machine-02 / primary_vm_zone
```

### `wf00-persistent-disk-05`

```text
project_id -> wf00-project / project_id
primary_vm_name -> wf00-virtual-machine-02 / primary_vm_name
vm_zone -> wf00-virtual-machine-02 / primary_vm_zone
```

### `wf00-gke-00`

```text
project_id -> wf00-project / project_id
network_self_link -> wf00-network / network_self_link
subnet_self_link -> wf00-network / subnet_self_link
```

### `wf00-gke-01`

```text
project_id -> wf00-project / project_id
network_self_link -> wf00-network / network_self_link
subnet_self_link -> wf00-network / subnet_self_link
```

### `wf00-gke-02`

```text
project_id -> wf00-project / project_id
network_self_link -> wf00-network / network_self_link
subnet_self_link -> wf00-network / subnet_self_link
```

## Example component Terraform files

### Project component `providers.tf`

```hcl
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.bootstrap_project_id
  region  = var.region
}

provider "google-beta" {
  project = var.bootstrap_project_id
  region  = var.region
}
```

### Network component `main.tf`

```hcl
locals {
  effective_network_name  = var.network_name != "" ? var.network_name : "${var.project_id}-vpc"
  effective_subnet_name   = var.subnet_name != "" ? var.subnet_name : "${var.project_id}-subnet"
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
```

### Bucket component `main.tf`

```hcl
locals {
  effective_prefix = var.bucket_name_prefix != "" ? var.bucket_name_prefix : "${var.project_id}-bkt"
  deployer_member  = trimspace(var.deployer_user_email) != "" ? "user:${trimspace(var.deployer_user_email)}" : ""
}

resource "random_id" "suffix" {
  count       = var.enable_bucket ? 1 : 0
  byte_length = 2
}

resource "google_storage_bucket" "bucket" {
  count                       = var.enable_bucket ? 1 : 0
  name                        = "${local.effective_prefix}-${random_id.suffix[0].hex}"
  project                     = var.project_id
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}
```

### Virtual Machine component `main.tf`

```hcl
locals {
  effective_count = var.enable_vms ? var.vm_count : 0
  name_prefix     = "${var.project_id}-vm"
}

resource "google_compute_instance" "vm" {
  count        = local.effective_count
  name         = "${local.name_prefix}-${count.index + 1}"
  machine_type = var.vm_machine_type
  zone         = var.vm_zone
  tags         = var.vm_tags

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
```

### Persistent Disk component `main.tf`

```hcl
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

resource "google_compute_attached_disk" "attach" {
  count       = local.should_attach ? 1 : 0
  project     = var.project_id
  zone        = local.effective_zone
  instance    = local.effective_vm_name
  disk        = google_compute_disk.pd[0].name
  device_name = var.device_name
}
```

### GKE component `main.tf`

```hcl
locals {
  effective_cluster_name = var.gke_cluster_name != "" ? var.gke_cluster_name : "${var.project_id}-gke"
  create_count           = var.enable_gke ? 1 : 0
}

resource "google_container_cluster" "cluster" {
  count    = local.create_count
  name     = local.effective_cluster_name
  location = var.gke_location

  network    = var.network_self_link
  subnetwork = var.subnet_self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {}

  release_channel {
    channel = var.gke_release_channel
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

resource "google_container_node_pool" "primary" {
  count    = local.create_count
  name     = "${local.effective_cluster_name}-np"
  location = var.gke_location
  cluster  = google_container_cluster.cluster[0].name

  node_count = var.gke_node_count

  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = var.gke_disk_size_gb

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env0_workflow = "wf-00"
      component     = "gke"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
```

## Deployment guidance

### Original workflow
Use the original child templates and workflow template if you want the initial WF-00 deployment.

### Larger workflow
Use the `_Large` child templates and the `v.1.1.2` workflow template if you want the scaled workflow in the same env0 Project without colliding with the original setup.

### Recommended isolation strategy
If the larger workflow is meant to evolve independently:

- keep the original workflow template and child templates untouched
- create new `_Large` child templates
- create a new workflow template that points to `v.1.1.2`
- keep child `revision:` values at `v.1.1.1` only if you intentionally want to keep the child code pinned there

## Final notes

- Keep `TF_VAR_existing_project_id` empty if you want a new GCP project created by GPF.
- Workflow Environment Outputs should be created as **Terraform Variables**, not Environment Variables.
- The Environment Output mappings belong on the **workflow template**, under each **consuming child environment**.
- The shared base set for this implementation is `artem_simulation_gcp_vars`.

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# Provider points to the target project (created/adopted by the Project component)
provider "google" {
  project = var.project_id
  region  = var.region
}

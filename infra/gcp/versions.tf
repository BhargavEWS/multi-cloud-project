terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.10"
    }
  }

  # Bucket is supplied at `terraform init -backend-config="bucket=<state-bucket-name>"`
  # so this file has no project-specific values in it (see README bootstrap steps).
  backend "gcs" {
    prefix = "multicloud-gitops-platform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

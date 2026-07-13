# GKE Autopilot: billed per-pod rather than per-node, which is the cheapest way
# to run a real cluster against free-trial credit for a portfolio project.
resource "google_container_cluster" "primary" {
  name     = "multicloud-gitops-cluster"
  location = var.region

  enable_autopilot = true

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.gke_subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  resource_labels = local.labels

  deletion_protection = false

  depends_on = [google_project_service.apis]
}

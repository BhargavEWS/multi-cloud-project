resource "google_artifact_registry_repository" "images" {
  location      = var.region
  repository_id = "taskflow"
  description   = "Container images for the taskflow-api sample app"
  format        = "DOCKER"

  labels = local.labels

  depends_on = [google_project_service.apis]
}

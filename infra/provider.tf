provider "google" {
  credentials = file("${path.module}/../token.json")
  project     = var.project_id
  region      = var.region
}

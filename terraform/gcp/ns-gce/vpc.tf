variable "project_id" {
  description = "project id"
}

variable "friendly_project_id" {
  description = "friendly project id, \"ns-gce\" not \"blabbertabber\""
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone within region"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.friendly_project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name             = "${var.friendly_project_id}-subnet"
  region           = var.region
  network          = google_compute_network.vpc.name
  ip_cidr_range    = "10.243.0.0/24"
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}

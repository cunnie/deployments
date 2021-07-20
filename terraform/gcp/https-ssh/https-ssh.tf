variable "project_id" {
  description = "project id"
}

variable "friendly_project_id" {
  description = "friendly project id, \"nono\" not \"blabbertabber\""
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
resource "google_compute_network" "https_ssh" {
  name                    = "${var.friendly_project_id}-https-ssh"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "https_ssh" {
  name          = "${var.friendly_project_id}-https-ssh"
  region        = var.region
  network       = google_compute_network.https_ssh.name
  ip_cidr_range = "10.20.30.0/24"
}

resource "google_compute_firewall" "https_ssh" {
  name    = "allow-everything"
  network = google_compute_network.https_ssh.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

# VN
resource "google_compute_instance" "vm" {
  name          = "${var.friendly_project_id}-https-ssh"
  machine_type  = "g1-small"
  zone = var.zone
  boot_disk {
    initialize_params {
      # image = "projects/debian-cloud/global/images/debian-10-buster-v20210701"
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2010-groovy-v20210716"
      size = 30
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.https_ssh.name
    access_config {
      nat_ip = "34.122.134.30"
    }
  }
}

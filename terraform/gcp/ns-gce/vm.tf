variable "ipv4_address" {
  description = "IPv4 for ns-gce.{nono,sslip}.io"
}

variable "ipv6_address" {
  description = "IPv6 for ns-gce.{nono,sslip}.io"
}

resource "google_compute_instance" "vm_instance" {
  name                      = "ns-gce"
  machine_type              = "e2-micro"
  zone                      = var.zone
  allow_stopping_for_update = true

  tags = ["nginx-instance"]

  boot_disk {
    initialize_params {
      image = "projects/fedora-cloud/global/images/fedora-cloud-base-gcp-38-1-6-x86-64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    stack_type = "IPV4_IPV6"
    subnetwork = "${var.friendly_project_id}-subnet"
    access_config {
      nat_ip                 = var.ipv4_address
      public_ptr_domain_name = "ns-gce.nono.io."
    }
    ipv6_access_config {
      external_ipv6               = var.ipv6_address
      external_ipv6_prefix_length = "96"
      name                        = "external-ipv6"
      network_tier                = "PREMIUM"
      public_ptr_domain_name      = "ns-gce.nono.io."
    }
  }
}

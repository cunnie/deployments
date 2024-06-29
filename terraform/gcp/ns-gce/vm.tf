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
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20240626"
      size  = 20
      type  = "pd-ssd"
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
  metadata = {
    user-data = <<EOF
#!/bin/bash
/bin/bash -xc "$(curl https://raw.githubusercontent.com/cunnie/bin/main/install_ns-gce.sh)"
EOF
  }
}

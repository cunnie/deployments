resource "google_compute_firewall" "ns-gce" {
  name    = "ns-gce"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_tags = ["web"]
}

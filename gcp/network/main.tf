data "google_compute_zones" "main" {
  status = "UP"
}

resource "google_compute_network" "main" {
  name                    = "${var.namespace}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.namespace}-private"
  ip_cidr_range = "10.1.0.0/24"
  network       = "${google_compute_network.main.self_link}"
}

#------------------------------------------------------------------------------
# firewalls
#------------------------------------------------------------------------------

resource "google_compute_firewall" "allow_ssh" {
  name        = "${var.namespace}-allow-ssh"
  description = "${var.namespace} ssh ports"
  network     = "${google_compute_network.main.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow_services" {
  name        = "${var.namespace}-allow-services"
  description = "${var.namespace} services ports"
  network     = "${google_compute_network.main.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8800"]
  }
}

resource "google_compute_firewall" "allow_internal" {
  name          = "${var.namespace}-allow-internal"
  description   = "${var.namespace} allow internal traffic"
  network       = "${google_compute_network.main.name}"
  source_ranges = ["10.0.0.0/16"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

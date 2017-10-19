# Firewall
resource "google_compute_firewall" "default" {
  name    = "${var.prefix}-default"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = [
    "${var.bastion_tag}",
  ]
  target_tags = [
    "${var.server_tag}",
    "${var.worker_tag}",
    "${var.nat_tag}",
  ]
}

resource "google_compute_firewall" "bastion" {
  name    = "${var.prefix}-bastion"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${var.admin_cidr_ingress}"]
  target_tags = [
    "${var.bastion_tag}",
  ]
}

resource "google_compute_firewall" "consul" {
  network     = "${google_compute_network.default.name}"
  name        = "${var.prefix}-consul"

  # Server RPC
  allow {
    protocol = "tcp"
    ports    = ["8300"]
  }

  # Client RPC
  allow {
    protocol = "tcp"
    ports    = ["8400"]
  }

  # Serf LAN
  allow {
    protocol = "tcp"
    ports    = ["8301"]
  }
  allow {
    protocol = "udp"
    ports    = ["8301"]
  }

  # HTTP
  allow {
    protocol = "tcp"
    ports    = ["8500"]
  }

  source_tags = [
    "${var.server_tag}",
    "${var.worker_tag}",
  ]
  target_tags = [
    "${var.server_tag}",
    "${var.worker_tag}",
  ]
}

resource "google_compute_firewall" "nomad" {
  network     = "${google_compute_network.default.name}"
  name        = "${var.prefix}-nomad"

  # HTTP
  allow {
    protocol = "tcp"
    ports    = ["4646"]
  }

  # RPC
  allow {
    protocol = "tcp"
    ports    = ["4647"]
  }

  # Serf gossip
  allow {
    protocol = "tcp"
    ports    = ["4648"]
  }
  allow {
    protocol = "udp"
    ports    = ["4648"]
  }

  # Emphemeral range
  allow {
    protocol = "tcp"
    ports    = ["22000-32000"]
  }

  source_tags = [
    "${var.server_tag}",
    "${var.worker_tag}",
  ]
  target_tags = [
    "${var.server_tag}",
    "${var.worker_tag}",
  ]
}

resource "google_compute_firewall" "static" {
  network     = "${google_compute_network.default.name}"
  name        = "${var.prefix}-static"

  # Fabio HTTP
  allow {
    protocol = "tcp"
    ports    = ["9999"]
  }

  # Fabio admin UI
  allow {
    protocol = "tcp"
    ports    = ["9998"]
  }

  # Consul UI
  allow {
    protocol = "tcp"
    ports    = ["8500"]
  }

  # Nomad UI
  allow {
    protocol = "tcp"
    ports    = ["4646"]
  }

  # Healthcheck
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["${var.internal_and_http_healthcheck_cidrs}", "${var.admin_cidr_ingress}"]
  target_tags = [
    "${var.worker_tag}"
  ]
}

resource "google_compute_firewall" "nat" {
  network     = "${google_compute_network.default.name}"
  name        = "${var.prefix}-nat"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_tags = [
    "${var.server_tag}",
    "${var.worker_tag}",
  ]
  target_tags = [
    "${var.nat_tag}"
  ]
}

# TODO: Tighten VPN traffic only to necessary ports/protocols
resource "google_compute_firewall" "vpn" {
  network     = "${google_compute_network.default.name}"
  name        = "${var.prefix}-vpn"

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  source_ranges = [
    "${var.remote_ip_range}",
  ]
  target_tags = [
    "${var.server_tag}",
    "${var.worker_tag}",
  ]
}

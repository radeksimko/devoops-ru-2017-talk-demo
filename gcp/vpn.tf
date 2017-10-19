resource "google_compute_vpn_gateway" "default" {
  name    = "${var.prefix}-vpn"
  network = "${google_compute_network.default.self_link}"
}

resource "google_compute_vpn_tunnel" "default" {
  name          = "${var.prefix}-tunnel"
  peer_ip       = "${var.vpn_peer_ip}"
  shared_secret = "${var.vpn_shared_secret}"
  ike_version   = "1"

  target_vpn_gateway = "${google_compute_vpn_gateway.default.self_link}"
  local_traffic_selector  = ["${google_compute_subnetwork.private.ip_cidr_range}"]
  remote_traffic_selector = ["${var.remote_ip_range}"]
}

resource "google_compute_forwarding_rule" "vpn-esp" {
  name        = "${var.prefix}-vpn-esp"
  region      = "${var.region}"
  ip_protocol = "ESP"
  ip_address  = "${google_compute_address.vpn.address}"
  target      = "${google_compute_vpn_gateway.default.self_link}"
}

resource "google_compute_forwarding_rule" "vpn-udp-500" {
  name        = "${var.prefix}-vpn-udp-500"
  region      = "${var.region}"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = "${google_compute_address.vpn.address}"
  target      = "${google_compute_vpn_gateway.default.self_link}"
}

resource "google_compute_forwarding_rule" "vpn-udp-4500" {
  name        = "${var.prefix}-vpn-udp-4500"
  region      = "${var.region}"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = "${google_compute_address.vpn.address}"
  target      = "${google_compute_vpn_gateway.default.self_link}"
}

resource "google_compute_route" "default" {
  name       = "${var.prefix}-vpn-route"
  network    = "${google_compute_network.default.self_link}"
  dest_range = "${var.remote_ip_range}"
  priority   = 800
  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.default.self_link}"
  tags        = ["${var.server_tag}", "${var.worker_tag}"]
}

resource "google_compute_address" "vpn" {
  name = "${var.prefix}-vpn"
}

output "vpn_ip" {
  value = "${google_compute_address.vpn.address}"
}
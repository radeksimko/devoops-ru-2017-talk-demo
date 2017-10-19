# Load balancer

resource "google_compute_backend_service" "consul_ui" {
  name        = "${var.prefix}-consul-ui"
  protocol    = "HTTP"
  port_name   = "consul-ui"
  timeout_sec = 10
  backend {
    group = "${google_compute_region_instance_group_manager.worker.instance_group}"
  }
  health_checks = ["${google_compute_health_check.consul.self_link}"]
}

resource "google_compute_backend_service" "fabio" {
  name        = "${var.prefix}-fabio"
  protocol    = "HTTP"
  port_name   = "fabio"
  timeout_sec = 10
  backend {
    group = "${google_compute_region_instance_group_manager.worker.instance_group}"
  }
  health_checks = ["${google_compute_health_check.fabio.self_link}"]
}

resource "google_compute_backend_service" "fabio_ui" {
  name        = "${var.prefix}-fabio-ui"
  protocol    = "HTTP"
  port_name   = "fabio-ui"
  timeout_sec = 10
  backend {
    group = "${google_compute_region_instance_group_manager.worker.instance_group}"
  }
  health_checks = ["${google_compute_health_check.fabio.self_link}"]
}

resource "google_compute_backend_service" "nomad_ui" {
  name        = "${var.prefix}-nomad-ui"
  protocol    = "HTTP"
  port_name   = "nomad-ui"
  timeout_sec = 10
  backend {
    group = "${google_compute_region_instance_group_manager.worker.instance_group}"
  }
  health_checks = ["${google_compute_health_check.nomad.self_link}"]
}

resource "google_compute_health_check" "consul" {
  name = "${var.prefix}-consul"
  timeout_sec        = 5
  check_interval_sec = 10

  http_health_check {
    request_path = "/v1/agent/self"
    port = 8500
  }
}

resource "google_compute_health_check" "fabio" {
  name         = "${var.prefix}-fabio"
  timeout_sec        = 5
  check_interval_sec = 10

  http_health_check {
    request_path = "/health"
    port = 9998
  }
}

resource "google_compute_health_check" "nomad" {
  name         = "${var.prefix}-nomad"
  timeout_sec        = 5
  check_interval_sec = 10

  http_health_check {
    request_path = "/v1/agent/self"
    port = 4646
  }
}

resource "google_compute_target_http_proxy" "public" {
  name        = "${var.prefix}-public"
  url_map     = "${google_compute_url_map.public.self_link}"
}

resource "google_compute_global_address" "public" {
  name = "${var.prefix}-public"
}

resource "google_compute_global_forwarding_rule" "public" {
  name       = "${var.prefix}-public"
  ip_address = "${google_compute_global_address.public.address}"
  port_range = "80"
  target     = "${google_compute_target_http_proxy.public.self_link}"
}

resource "google_compute_url_map" "public" {
  name        = "${var.prefix}-public"

  default_service = "${google_compute_backend_service.fabio.self_link}"

  # Consul UI
  host_rule {
    hosts        = ["consul.${substr(data.google_dns_managed_zone.gcp.dns_name, 0, length(data.google_dns_managed_zone.gcp.dns_name)-1)}"]
    path_matcher = "consul-ui"
  }
  path_matcher {
    name            = "consul-ui"
    default_service = "${google_compute_backend_service.consul_ui.self_link}"
  }


  # Fabio UI
  host_rule {
    hosts        = ["fabio.${substr(data.google_dns_managed_zone.gcp.dns_name, 0, length(data.google_dns_managed_zone.gcp.dns_name)-1)}"]
    path_matcher = "fabio-ui"
  }
  path_matcher {
    name            = "fabio-ui"
    default_service = "${google_compute_backend_service.fabio_ui.self_link}"
  }

  # Nomad UI
  host_rule {
    hosts        = ["nomad.${substr(data.google_dns_managed_zone.gcp.dns_name, 0, length(data.google_dns_managed_zone.gcp.dns_name)-1)}"]
    path_matcher = "nomad-ui"
  }
  path_matcher {
    name            = "nomad-ui"
    default_service = "${google_compute_backend_service.nomad_ui.self_link}"
  }
}

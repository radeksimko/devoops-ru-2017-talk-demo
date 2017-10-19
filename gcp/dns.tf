data "google_dns_managed_zone" "gcp" {
  name = "${var.zone_name}"
}

resource "google_dns_record_set" "www" {
  name = "www.${data.google_dns_managed_zone.gcp.dns_name}"
  type = "A"
  ttl  = 5

  managed_zone = "${data.google_dns_managed_zone.gcp.name}"
  rrdatas = ["${google_compute_global_forwarding_rule.public.ip_address}"]
}

resource "google_dns_record_set" "consul" {
  name = "consul.${data.google_dns_managed_zone.gcp.dns_name}"
  type = "A"
  ttl  = 5

  managed_zone = "${data.google_dns_managed_zone.gcp.name}"
  rrdatas = ["${google_compute_global_forwarding_rule.public.ip_address}"]
}

resource "google_dns_record_set" "fabio" {
  name = "fabio.${data.google_dns_managed_zone.gcp.dns_name}"
  type = "A"
  ttl  = 5

  managed_zone = "${data.google_dns_managed_zone.gcp.name}"
  rrdatas = ["${google_compute_global_forwarding_rule.public.ip_address}"]
}

resource "google_dns_record_set" "nomad" {
  name = "nomad.${data.google_dns_managed_zone.gcp.dns_name}"
  type = "A"
  ttl  = 5

  managed_zone = "${data.google_dns_managed_zone.gcp.name}"
  rrdatas = ["${google_compute_global_forwarding_rule.public.ip_address}"]
}

output "lb" {
  value = "${google_compute_global_forwarding_rule.public.ip_address}"
}

output "www" {
  value = "${google_dns_record_set.www.name}"
}

output "consul_ui" {
  value = "${google_dns_record_set.consul.name}"
}

output "fabio_ui" {
  value = "${google_dns_record_set.fabio.name}"
}

output "nomad_ui" {
  value = "${google_dns_record_set.nomad.name}"
}

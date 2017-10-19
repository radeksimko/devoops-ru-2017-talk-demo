output "lb" {
  value = "${aws_alb.public.dns_name}"
}

output "www" {
  value = "${aws_route53_record.www.fqdn}"
}

output "consul_ui" {
  value = "${aws_route53_record.consul.fqdn}"
}

output "fabio_ui" {
  value = "${aws_route53_record.fabio.fqdn}"
}

output "nomad_ui" {
  value = "${aws_route53_record.nomad.fqdn}"
}

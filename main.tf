variable "aws_network_cidr" {
  default = "10.10.0.0/24"
}
variable "gcp_network_cidr" {
  default = "10.10.10.0/24"
}

# AWS
module "aws" {
  source = "./aws"
  region = "eu-west-2"
  network_cidr = "${var.aws_network_cidr}"
  prefix = "devoops"
  zone_name = "aws.radeksimko.com"
  vpn_peer_ip = "${module.gcp.vpn_ip}"
  remote_ip_range = "${var.gcp_network_cidr}"
  admin_cidr_ingress = "${var.admin_cidr_ingress}"
}

output "aws_lb" {
  value = "${module.aws.lb}"
}

output "aws_www" {
  value = "${module.aws.www}"
}

output "aws_consul_ui" {
  value = "${module.aws.consul_ui}"
}

output "aws_fabio_ui" {
  value = "${module.aws.fabio_ui}"
}

output "aws_nomad_ui" {
  value = "${module.aws.nomad_ui}"
}

# GCP
module "gcp" {
  source = "./gcp"
  region = "europe-west2"
  network_cidr = "${var.gcp_network_cidr}"
  prefix = "devoops"
  zone_name = "radek-gcp-demo"
  vpn_peer_ip = "${module.aws.vpn_ip}"
  vpn_shared_secret = "${module.aws.vpn_preshared_key}"
  remote_ip_range = "${var.aws_network_cidr}"
  admin_cidr_ingress = "${var.admin_cidr_ingress}"
}

output "gcp_lb" {
  value = "${module.gcp.lb}"
}

output "gcp_www" {
  value = "${module.gcp.www}"
}

output "gcp_consul_ui" {
  value = "${module.gcp.consul_ui}"
}

output "gcp_fabio_ui" {
  value = "${module.gcp.fabio_ui}"
}

output "gcp_nomad_ui" {
  value = "${module.gcp.nomad_ui}"
}

# TODO: Global LB solution

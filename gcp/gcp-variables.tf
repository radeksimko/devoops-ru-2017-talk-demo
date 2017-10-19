variable "region" {}
variable "network_cidr" {}
variable "prefix" {}
variable "zone_name" {}

# VPN
variable "vpn_peer_ip" {}
variable "vpn_shared_secret" {}
variable "remote_ip_range" {}

# Tags

variable "server_tag" {
  default = "devoops-server"
}

variable "worker_tag" {
  default = "devoops-worker"
}

variable "bastion_tag" {
  default = "devoops-bastion"
}

variable "nat_tag" {
  default = "devoops-nat"
}

# Capacity

variable "server_desired_capacity" {
  default = 3
}
variable "worker_desired_capacity" {
  default = 3
}

# TODO (data sources): https://github.com/terraform-providers/terraform-provider-google/pull/567
variable "internal_and_http_healthcheck_cidrs" {
  default = ["130.211.0.0/22", "35.191.0.0/16"]
}

variable "external_healthcheck_cidrs" {
  default = ["209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"]
}
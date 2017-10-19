variable "region" {}
variable "prefix" {}
variable "network_cidr" {}
variable "zone_name" {}

# VPN
variable "vpn_peer_ip" {}
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
variable "server_min_capacity" {
  default = 3
}
variable "server_max_capacity" {
  default = 5
}
variable "server_desired_capacity" {
  default = 3
}

variable "worker_min_capacity" {
  default = 3
}
variable "worker_max_capacity" {
  default = 5
}
variable "worker_desired_capacity" {
  default = 3
}

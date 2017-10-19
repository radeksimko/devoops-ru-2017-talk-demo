resource "google_compute_network" "default" {
  name = "${var.prefix}-default"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.prefix}-private-${var.region}"
  ip_cidr_range = "${cidrsubnet(var.network_cidr, 4, 0)}"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region}"
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.prefix}-public-${var.region}"
  ip_cidr_range = "${cidrsubnet(var.network_cidr, 4, 1)}"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region}"
}

resource "google_compute_route" "public" {
  name        = "${var.prefix}-igw-route"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.default.name}"
  next_hop_gateway = "default-internet-gateway"
  priority    = 100
  tags        = ["${var.nat_tag}", "${var.bastion_tag}"]
}

resource "google_compute_route" "private" {
  count       = "${length(data.google_compute_zones.available.names)}"
  name        = "${var.prefix}-nat-route-${count.index}"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.default.name}"
  next_hop_ip = "${google_compute_address.nat-internal.*.address[count.index]}"
  priority    = 800
  tags        = ["${var.server_tag}", "${var.worker_tag}"]
}

# Bastion

resource "google_compute_region_instance_group_manager" "bastion" {
  name        = "${var.prefix}-bastion"

  base_instance_name = "${var.prefix}-bastion-i"
  instance_template  = "${google_compute_instance_template.bastion.self_link}"
  region             = "${var.region}"
  target_size        = 1
}

resource "google_compute_instance_template" "bastion" {
  tags = ["${var.bastion_tag}"]

  machine_type = "n1-standard-1"
  region = "${var.region}"

  disk {
    device_name = "persistent-disk-0"
    source_image = "coreos-cloud/coreos-stable"
    auto_delete  = true
    boot         = true
  }

  metadata {
    "sshKeys" = "core:${file("~/.ssh/id_rsa.pub")}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.public.name}"
    access_config {
      // Ephemeral IP
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


# NAT
data "template_file" "gcp_nat_cloud_config" {
  template = "${file("${path.module}/../templates/nat-cloud-config.yml")}"
  vars {
    role          = "${data.template_file.gcp_role_worker.rendered}"
  }
}

resource "google_compute_instance" "nat" {
  count = "${length(data.google_compute_zones.available.names)}"
  name = "${var.prefix}-nat-${data.google_compute_zones.available.names[count.index]}"
  tags = ["${var.nat_tag}"]
  machine_type = "g1-small"
  zone = "${data.google_compute_zones.available.names[count.index]}"
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "coreos-cloud/coreos-stable"
    }
  }
  metadata {
    "user-data" = "${data.template_file.gcp_nat_cloud_config.rendered}"
    "sshKeys" = "core:${file("~/.ssh/id_rsa.pub")}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.public.name}"
    address = "${google_compute_address.nat-internal.*.address[count.index]}"
    access_config {
      nat_ip = "${google_compute_address.nat-external.*.address[count.index]}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_address" "nat-internal" {
  count        = "${length(data.google_compute_zones.available.names)}"
  name         = "${var.prefix}-int-nat-${count.index}"
  address_type = "INTERNAL"
  subnetwork   = "${google_compute_subnetwork.public.self_link}"
}

resource "google_compute_address" "nat-external" {
  count        = "${length(data.google_compute_zones.available.names)}"
  name         = "${var.prefix}-ext-nat-${count.index}"
}

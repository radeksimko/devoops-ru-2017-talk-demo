provider "google" {
  region = "${var.region}"
}

data "google_compute_zones" "available" {}

# Server
data "template_file" "gcp_role_server" {
  template = "${file("${path.module}/../templates/colour-red.sh")}"
  vars {
    message = "server"
  }
}
data "template_file" "gcp_consul_server" {
  template = "${file("${path.module}/../templates/consul-server.hcl")}"
  vars {
    provider         = "gce"
    region           = "${var.region}"
    tag_value        = "${var.server_tag}"
    desired_capacity = "${length(data.google_compute_zones.available.names)}"
  }
}
data "template_file" "gcp_nomad_server" {
  template = "${file("${path.module}/../templates/nomad-server.hcl")}"
  vars {
    provider         = "gce"
    region           = "${var.region}"
    desired_capacity = "${length(data.google_compute_zones.available.names)}"
  }
}

data "template_file" "gcp_server_cloud_config" {
  template = "${file("${path.module}/../templates/cloud-config.yml")}"
  vars {
    role          = "${data.template_file.gcp_role_server.rendered}"
    consul_config = "${base64encode(data.template_file.gcp_consul_server.rendered)}"
    nomad_config  = "${base64encode(data.template_file.gcp_nomad_server.rendered)}"
  }
}

resource "google_compute_region_instance_group_manager" "server" {
  name        = "${var.prefix}-server"

  base_instance_name = "${var.prefix}-server-i"
  instance_template  = "${google_compute_instance_template.server.self_link}"
  region             = "${var.region}"

  target_size  = "${length(data.google_compute_zones.available.names)}"
}

resource "google_compute_instance_template" "server" {
  tags = ["${var.server_tag}"]

  machine_type = "n1-standard-1"
  region = "${var.region}"

  disk {
    device_name = "persistent-disk-0"
    source_image = "coreos-cloud/coreos-stable"
    auto_delete  = true
    boot         = true
  }

  metadata {
    "user-data" = "${data.template_file.gcp_server_cloud_config.rendered}"
    "sshKeys" = "core:${file("~/.ssh/id_rsa.pub")}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.private.name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    scopes = ["compute-ro"]
  }
}

# Worker
data "template_file" "gcp_role_worker" {
  template = "${file("${path.module}/../templates/colour-yellow.sh")}"
  vars {
    message = "worker"
  }
}

data "template_file" "gcp_consul_worker" {
  template = "${file("${path.module}/../templates/consul-client.hcl")}"
  vars {
    provider       = "gce"
    role           = "worker"
    enable_ui      = "true"
    iface_name     = "ens4v1"
    client_address = "127.0.0.1 {{ GetInterfaceIP \\\"ens4v1\\\" }}"
    region         = "${var.region}"
    tag_value      = "${var.server_tag}"
  }
}
data "template_file" "gcp_nomad_worker" {
  template = "${file("${path.module}/../templates/nomad-client.hcl")}"
  vars {
    provider = "gce"
    role     = "worker"
    region   = "${var.region}"
  }
}

data "template_file" "gcp_worker_cloud_config" {
  template = "${file("${path.module}/../templates/cloud-config.yml")}"
  vars {
    role          = "${data.template_file.gcp_role_worker.rendered}"
    consul_config = "${base64encode(data.template_file.gcp_consul_worker.rendered)}"
    nomad_config  = "${base64encode(data.template_file.gcp_nomad_worker.rendered)}"
  }
}

resource "google_compute_region_instance_group_manager" "worker" {
  name        = "${var.prefix}-worker"

  base_instance_name = "${var.prefix}-worker-i"
  instance_template  = "${google_compute_instance_template.worker.self_link}"
  region             = "${var.region}"
  target_size        = "${length(data.google_compute_zones.available.names)}"

  named_port {
    name = "consul-ui"
    port = 8500
  }

  named_port {
    name = "fabio"
    port = 9999
  }

  named_port {
    name = "fabio-ui"
    port = 9998
  }

  named_port {
    name = "nomad-ui"
    port = 4646
  }
}

resource "google_compute_instance_template" "worker" {
  tags = ["${var.worker_tag}"]

  machine_type = "n1-standard-1"
  region = "${var.region}"

  disk {
    device_name = "persistent-disk-0"
    source_image = "coreos-cloud/coreos-stable"
    auto_delete  = true
    boot         = true
  }

  metadata {
    "user-data" = "${data.template_file.gcp_worker_cloud_config.rendered}"
    "sshKeys" = "core:${file("~/.ssh/id_rsa.pub")}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.private.name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    scopes = ["compute-ro"]
  }
}

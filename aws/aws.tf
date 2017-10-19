provider "aws" {
  region = "${var.region}"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "stable_coreos" {
  most_recent = true

  filter {
    name   = "description"
    values = ["CoreOS Container Linux stable *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}

# IAM

resource "aws_iam_instance_profile" "demo" {
  name  = "${var.prefix}_demo"
  role = "${aws_iam_role.demo.name}"
}

resource "aws_iam_role" "demo" {
  name = "${var.prefix}_demo"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "demo" {
  name = "${var.prefix}_demo"
  role = "${aws_iam_role.demo.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Key pair

resource "aws_key_pair" "demo" {
  key_name   = "${var.prefix}-demo"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Server
data "template_file" "role_server" {
  template = "${file("${path.module}/../templates/colour-red.sh")}"
  vars {
    message = "server"
  }
}
data "template_file" "consul_server" {
  template = "${file("${path.module}/../templates/consul-server.hcl")}"
  vars {
    provider         = "aws"
    region           = "${var.region}"
    tag_value        = "${var.server_tag}"
    desired_capacity = "${var.server_desired_capacity}"
  }
}
data "template_file" "nomad_server" {
  template = "${file("${path.module}/../templates/nomad-server.hcl")}"
  vars {
    provider         = "aws"
    region           = "${var.region}"
    desired_capacity = "${var.server_desired_capacity}"
  }
}

data "template_file" "server_cloud_config" {
  template = "${file("${path.module}/../templates/cloud-config.yml")}"
  vars {
    role          = "${data.template_file.role_server.rendered}"
    consul_config = "${base64encode(data.template_file.consul_server.rendered)}"
    nomad_config  = "${base64encode(data.template_file.nomad_server.rendered)}"
  }
}

resource "aws_launch_configuration" "server" {
  name_prefix   = "${var.prefix}_server_"
  image_id      = "${data.aws_ami.stable_coreos.id}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.demo.key_name}"
  security_groups = [
    "${aws_security_group.private.id}",
    "${aws_security_group.consul.id}",
    "${aws_security_group.nomad.id}",
  ]
  user_data = "${data.template_file.server_cloud_config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.demo.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "server" {
  name_prefix               = "${var.prefix}_server_"
  max_size                  = "${var.server_max_capacity}"
  min_size                  = "${var.server_min_capacity}"
  desired_capacity          = "${var.server_desired_capacity}"
  health_check_grace_period = 60
  default_cooldown          = 1
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.server.name}"
  vpc_zone_identifier       = ["${aws_subnet.private.*.id}"]

  tag {
    key                 = "Name"
    value               = "${var.server_tag}"
    propagate_at_launch = true
  }
}

# Worker

data "template_file" "role_worker" {
  template = "${file("${path.module}/../templates/colour-yellow.sh")}"
  vars {
    message = "worker"
  }
}

data "template_file" "consul_worker" {
  template = "${file("${path.module}/../templates/consul-client.hcl")}"
  vars {
    provider       = "aws"
    role           = "worker"
    enable_ui      = "true"
    iface_name     = "eth0"
    client_address = "127.0.0.1 {{ GetInterfaceIP \\\"eth0\\\" }}"
    region         = "${var.region}"
    tag_value      = "${var.server_tag}"
  }
}

data "template_file" "nomad_worker" {
  template = "${file("${path.module}/../templates/nomad-client.hcl")}"
  vars {
    provider = "aws"
    role     = "worker"
    region   = "${var.region}"
  }
}

data "template_file" "worker_cloud_config" {
  template = "${file("${path.module}/../templates/cloud-config.yml")}"
  vars {
    role          = "${data.template_file.role_worker.rendered}"
    consul_config = "${base64encode(data.template_file.consul_worker.rendered)}"
    nomad_config  = "${base64encode(data.template_file.nomad_worker.rendered)}"
  }
}

resource "aws_launch_configuration" "worker" {
  name_prefix   = "${var.prefix}_worker_"
  image_id      = "${data.aws_ami.stable_coreos.id}"
  instance_type = "t2.small"
  key_name = "${aws_key_pair.demo.key_name}"
  security_groups = [
    "${aws_security_group.private.id}",
    "${aws_security_group.consul.id}",
    "${aws_security_group.nomad.id}",
    "${aws_security_group.frontend.id}",
  ]
  user_data = "${data.template_file.worker_cloud_config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.demo.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "worker" {
  name_prefix               = "${var.prefix}_worker_"
  max_size                  = "${var.worker_max_capacity}"
  min_size                  = "${var.worker_min_capacity}"
  desired_capacity          = "${var.worker_desired_capacity}"
  health_check_grace_period = 60
  default_cooldown          = 1
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.worker.name}"
  vpc_zone_identifier       = ["${aws_subnet.private.*.id}"]
  target_group_arns         = [
    "${aws_alb_target_group.consul.arn}",
    "${aws_alb_target_group.fabio.arn}",
    "${aws_alb_target_group.fabio_ui.arn}",
    "${aws_alb_target_group.nomad.arn}",
  ]

  tag {
    key                 = "Name"
    value               = "${var.worker_tag}"
    propagate_at_launch = true
  }
}

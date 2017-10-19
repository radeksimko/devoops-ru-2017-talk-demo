resource "aws_vpc" "main" {
  cidr_block = "${var.network_cidr}"
  tags {
    Name = "${var.prefix}-main"
  }
}

resource "aws_subnet" "private" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"
  tags {
    Name = "${var.prefix}-private-${count.index}"
  }
}

resource "aws_subnet" "public" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 4, length(data.aws_availability_zones.available.names)+count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"
  tags {
    Name = "${var.prefix}-public-${count.index}"
  }
}

resource "aws_eip" "nat" {
  count = "${length(data.aws_availability_zones.available.names)}"
}

resource "aws_nat_gateway" "gw" {
  count         = "${length(data.aws_availability_zones.available.names)}"
  allocation_id = "${aws_eip.nat.*.id[count.index]}"
  subnet_id     = "${aws_subnet.public.*.id[count.index]}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    Name = "${var.prefix}-public"
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${aws_subnet.public.*.id[count.index]}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.*.id[count.index]}"
  }

  route {
    cidr_block = "${var.remote_ip_range}"
    gateway_id = "${aws_vpn_gateway.default.id}"
  }

  tags {
    Name = "${var.prefix}-private-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"
}

# Bastion

resource "aws_launch_configuration" "bastion" {
  name_prefix   = "${var.prefix}_bastion_"
  image_id      = "${data.aws_ami.stable_coreos.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.demo.key_name}"
  associate_public_ip_address = true
  security_groups = [
    "${aws_security_group.bastion.id}",
  ]
  iam_instance_profile = "${aws_iam_instance_profile.demo.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name_prefix               = "${var.prefix}_bastion_"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 60
  default_cooldown          = 1
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.bastion.name}"
  vpc_zone_identifier       = ["${aws_subnet.public.*.id}"]

  tag {
    key                 = "Name"
    value               = "${var.bastion_tag}"
    propagate_at_launch = true
  }
}

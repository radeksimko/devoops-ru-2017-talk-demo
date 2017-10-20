# SGs

resource "aws_security_group" "private" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "${var.prefix}-private"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  # VPN remote range
  # TODO: Tighten VPN traffic only to necessary ports/protocols
  ingress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["${var.remote_ip_range}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "${var.prefix}-bastion"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      "${var.admin_cidr_ingress}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "consul" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "${var.prefix}-consul"

  # Server RPC
  ingress {
    protocol = "tcp"
    from_port = 8300
    to_port   = 8300
    self      = true
  }

  # Client RPC
  ingress {
    protocol = "tcp"
    from_port = 8400
    to_port   = 8400
    self      = true
  }

  # Serf LAN
  ingress {
    protocol = "tcp"
    from_port = 8301
    to_port   = 8301
    self      = true
  }
  ingress {
    protocol = "udp"
    from_port = 8301
    to_port   = 8301
    self      = true
  }

  # HTTP
  ingress {
    protocol = "tcp"
    from_port = 8500
    to_port   = 8500
    self      = true
  }
}

resource "aws_security_group" "nomad" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "${var.prefix}-nomad"

  # HTTP
  ingress {
    protocol = "tcp"
    from_port = 4646
    to_port   = 4646
    self      = true
  }

  # RPC
  ingress {
    protocol = "tcp"
    from_port = 4647
    to_port   = 4647
    self      = true
  }

  # Serf gossip
  ingress {
    protocol = "tcp"
    from_port = 4648
    to_port   = 4648
    self      = true
  }
  ingress {
    protocol = "udp"
    from_port = 4648
    to_port   = 4648
    self      = true
  }

  # Emphemeral range
  ingress {
    protocol = "tcp"
    from_port = 22000
    to_port   = 32000
    self      = true
  }
}

resource "aws_security_group" "frontend" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "${var.prefix}-frontend"

  # Fabio admin UI
  ingress {
    protocol = "tcp"
    from_port = 9998
    to_port   = 9998
    cidr_blocks = ["${aws_subnet.public.*.cidr_block}", "${var.admin_cidr_ingress}"]
  }

  # Consul UI
  ingress {
    protocol = "tcp"
    from_port = 8500
    to_port   = 8500
    cidr_blocks = ["${aws_subnet.public.*.cidr_block}", "${var.admin_cidr_ingress}"]
  }

  # Nomad UI
  ingress {
    protocol = "tcp"
    from_port = 4646
    to_port   = 4646
    cidr_blocks = ["${aws_subnet.public.*.cidr_block}"]
  }

  # Fabio HTTP
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = ["${aws_subnet.public.*.cidr_block}", "${var.admin_cidr_ingress}"]
  }
}

resource "aws_security_group" "lb" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "${var.prefix}-lb"

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = ["${var.admin_cidr_ingress}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

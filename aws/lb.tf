# Load balancer
resource "aws_alb" "public" {
  name            = "${var.prefix}-public"
  internal        = false
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id = "${aws_subnet.public.0.id}"
    allocation_id = "${aws_eip.lb.0.id}"
  }
  subnet_mapping {
    subnet_id = "${aws_subnet.public.1.id}"
    allocation_id = "${aws_eip.lb.1.id}"
  }

  tags {
    Environment = "${var.prefix}-public"
  }
}

resource "aws_eip" "lb" {
  count = "${length(data.aws_availability_zones.available.names)}"
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = "${aws_alb.public.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_alb_target_group.fabio.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "consul_ui" {
  load_balancer_arn = "${aws_alb.public.arn}"
  port              = "8500"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_alb_target_group.consul.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "nomad_ui" {
  load_balancer_arn = "${aws_alb.public.arn}"
  port              = "4646"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_alb_target_group.nomad.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "fabio_ui" {
  load_balancer_arn = "${aws_alb.public.arn}"
  port              = "9998"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_alb_target_group.fabio_ui.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "fabio" {
  name     = "${var.prefix}-fabio"
  port     = 9999
  protocol = "TCP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    port = 9998
    protocol = "TCP"
  }
}

resource "aws_alb_target_group" "fabio_ui" {
  name     = "${var.prefix}-fabio-ui"
  port     = 9998
  protocol = "TCP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    port = 9998
    protocol = "TCP"
  }
}

# resource "aws_alb_listener_rule" "fabio_ui" {
#   listener_arn = "${aws_alb_listener.http.arn}"
#   priority     = 140

#   action {
#     type             = "forward"
#     target_group_arn = "${aws_alb_target_group.fabio_ui.arn}"
#   }

#   condition {
#     field  = "host-header"
#     values = ["${aws_route53_record.fabio.fqdn}"]
#   }
# }

resource "aws_alb_target_group" "consul" {
  name     = "${var.prefix}-consul"
  port     = 8500
  protocol = "TCP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    protocol = "TCP"
  }
}

# resource "aws_alb_listener_rule" "consul_ui" {
#   listener_arn = "${aws_alb_listener.http.arn}"
#   priority     = 150

#   action {
#     type             = "forward"
#     target_group_arn = "${aws_alb_target_group.consul.arn}"
#   }

#   condition {
#     field  = "host-header"
#     values = ["${aws_route53_record.consul.fqdn}"]
#   }
# }

resource "aws_alb_target_group" "nomad" {
  name     = "${var.prefix}-nomad"
  port     = 4646
  protocol = "TCP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    protocol = "TCP"
  }
}

# resource "aws_alb_listener_rule" "nomad_ui" {
#   listener_arn = "${aws_alb_listener.http.arn}"
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = "${aws_alb_target_group.nomad.arn}"
#   }

#   condition {
#     field  = "host-header"
#     values = ["${aws_route53_record.nomad.fqdn}"]
#   }
# }

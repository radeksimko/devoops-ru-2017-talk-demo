# Load balancer
resource "aws_alb" "public" {
  name            = "${var.prefix}-public"
  internal        = false
  security_groups = ["${aws_security_group.lb.id}"]
  subnets         = ["${aws_subnet.public.*.id}"]

  tags {
    Environment = "${var.prefix}-public"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = "${aws_alb.public.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.fabio.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "fabio" {
  name     = "${var.prefix}-fabio"
  port     = 9999
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    port = 9998
    path = "/health"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_target_group" "fabio_ui" {
  name     = "${var.prefix}-fabio-ui"
  port     = 9998
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    port = 9998
    path = "/health"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener_rule" "fabio_ui" {
  listener_arn = "${aws_alb_listener.http.arn}"
  priority     = 140

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.fabio_ui.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${aws_route53_record.fabio.fqdn}"]
  }
}

resource "aws_alb_target_group" "consul" {
  name     = "${var.prefix}-consul"
  port     = 8500
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    path = "/v1/agent/self"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener_rule" "consul_ui" {
  listener_arn = "${aws_alb_listener.http.arn}"
  priority     = 150

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.consul.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${aws_route53_record.consul.fqdn}"]
  }
}

resource "aws_alb_target_group" "nomad" {
  name     = "${var.prefix}-nomad"
  port     = 4646
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    path = "/v1/agent/self"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener_rule" "nomad_ui" {
  listener_arn = "${aws_alb_listener.http.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.nomad.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${aws_route53_record.nomad.fqdn}"]
  }
}

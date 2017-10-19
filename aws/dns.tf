data "aws_route53_zone" "aws" {
  name = "${var.zone_name}"
}

resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.aws.zone_id}"
  name    = "www.${data.aws_route53_zone.aws.name}"
  type    = "A"
  alias {
    name                   = "${aws_alb.public.dns_name}"
    zone_id                = "${aws_alb.public.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "consul" {
  zone_id = "${data.aws_route53_zone.aws.zone_id}"
  name    = "consul.${data.aws_route53_zone.aws.name}"
  type    = "A"
  alias {
    name                   = "${aws_alb.public.dns_name}"
    zone_id                = "${aws_alb.public.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "fabio" {
  zone_id = "${data.aws_route53_zone.aws.zone_id}"
  name    = "fabio.${data.aws_route53_zone.aws.name}"
  type    = "A"
  alias {
    name                   = "${aws_alb.public.dns_name}"
    zone_id                = "${aws_alb.public.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "nomad" {
  zone_id = "${data.aws_route53_zone.aws.zone_id}"
  name    = "nomad.${data.aws_route53_zone.aws.name}"
  type    = "A"
  alias {
    name                   = "${aws_alb.public.dns_name}"
    zone_id                = "${aws_alb.public.zone_id}"
    evaluate_target_health = true
  }
}

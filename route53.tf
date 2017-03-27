resource "aws_route53_zone" "cognoma" {
  name = "cognoma.org"
}

resource "aws_route53_record" "cognoma-dot-org" {
  zone_id = "${aws_route53_zone.cognoma.zone_id}"
  name    = "cognoma.org"
  type    = "A"
  ttl     = "300"

  records = [
    "192.30.252.153",
    "192.30.252.153",
  ]
}

resource "aws_route53_record" "cognoma-api" {
  zone_id = "${aws_route53_zone.cognoma.zone_id}"
  name    = "api.cognoma.org"
  type    = "A"

  alias {
    name = "${aws_elb.cognoma-nginx.name}"
    zone_id = "${aws_elb.cognoma-nginx.zone_id}"
    evaluate_target_health = false
  }
}

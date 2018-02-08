# resource "aws_route53_zone" "cognoma" {
#   name = "cognoma.org"
# }

data "aws_route53_zone" "cognoma" {
  zone_id = "Z1D5X4ZSR5R6N1"
}

resource "aws_route53_record" "cognoma-dot-org" {
  zone_id = "${data.aws_route53_zone.cognoma.zone_id}"
  name    = "cognoma.org"
  type    = "A"
  ttl     = "300"

  records = [
    "192.30.252.153",
    "192.30.252.153",
  ]
}

resource "aws_route53_record" "cognoma-api" {
  zone_id = "${data.aws_route53_zone.cognoma.zone_id}"
  name    = "api.cognoma.org"
  type    = "A"

  alias {
    name = "${aws_elb.cognoma-nginx.dns_name}"
    zone_id = "${aws_elb.cognoma-nginx.zone_id}"
    evaluate_target_health = false
  }
}

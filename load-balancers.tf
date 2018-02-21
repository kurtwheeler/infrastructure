resource "aws_elb" "cognoma-core" {
  name = "cognoma-core-service"
  subnets = [
    "${aws_subnet.cognoma-1a.id}",
    "${aws_subnet.cognoma-1b.id}"]

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:8000/"
    interval = 30
  }

  security_groups = ["${aws_security_group.cognoma-service.id}"]

  instances = [
    "${aws_instance.cognoma-service-1.id}",
    "${aws_instance.cognoma-service-2.id}",
  ]

  cross_zone_load_balancing = true
  idle_timeout = 60
  connection_draining = true
  connection_draining_timeout = 400
  internal = true
}

data "aws_acm_certificate" "cognoma-ssl-cert" {
  domain   = "api.cognoma.org"
  statuses = ["ISSUED"]
}

resource "aws_elb" "cognoma-nginx" {
  name = "cognoma-nginx"
  subnets = [
    "${aws_subnet.cognoma-1a.id}",
    "${aws_subnet.cognoma-1b.id}"
  ]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.cognoma-ssl-cert.arn}"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 2
    timeout = 5
    target = "TCP:80"
    interval = 30
  }

  security_groups = [
    "${aws_security_group.cognoma-service.id}",
    "${aws_security_group.cognoma-public-elb.id}"
  ]

  instances = [
    "${aws_instance.cognoma-service-1.id}",
    "${aws_instance.cognoma-service-2.id}"
  ]

  cross_zone_load_balancing = true
  idle_timeout = 60
  connection_draining = true
  connection_draining_timeout = 400
}

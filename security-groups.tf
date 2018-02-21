resource "aws_security_group" "cognoma-service" {
  name = "cognoma-service"
  description = "cognoma-service"
  vpc_id = "${aws_vpc.cognoma-vpc.id}"

  tags {
    Name = "cognoma-service"
  }
}

resource "aws_security_group_rule" "cognoma-service-http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  self = true
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

resource "aws_security_group_rule" "cognoma-service-custom" {
  type = "ingress"
  from_port = 8000
  to_port = 8000
  protocol = "tcp"
  self = true
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

# The ELB needs to be able to make outbound http requests to the
# intances for health checks
resource "aws_security_group_rule" "cognoma-service-elb-outbound" {
  type = "egress"
  from_port = 8000
  to_port = 8000
  protocol = "tcp"
  self = true
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

resource "aws_security_group_rule" "cognoma-service-ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

resource "aws_security_group_rule" "cognoma-service-outbound-http" {
  type = "egress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

resource "aws_security_group_rule" "cognoma-service-outbound-https" {
  type = "egress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

resource "aws_security_group" "cognoma-public-elb" {
  name = "cognoma-public-elb"
  description = "cognoma-public-elb"
  vpc_id = "${aws_vpc.cognoma-vpc.id}"

  tags {
    Name = "cognoma-public-elb"
  }
}

resource "aws_security_group_rule" "cognoma-public-elb-all" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.cognoma-service.id}"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "cognoma-public-elb-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cognoma-public-elb.id}"
}

resource "aws_security_group" "cognoma-db" {
  name = "cognoma-db"
  description = "cognoma-db"
  vpc_id = "${aws_vpc.cognoma-vpc.id}"

  tags {
    Name = "cognoma-db"
  }
}

# Allow RDS instance to accept inbound postgres connections from cognoma service instances
resource "aws_security_group_rule" "cognoma-db-from-instance" {
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cognoma-service.id}"
  security_group_id = "${aws_security_group.cognoma-db.id}"
}

# Allow the cognoma service instances to make outbound postgres connections to RDS instance
resource "aws_security_group_rule" "cognoma-instance-to-db" {
  type = "egress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cognoma-db.id}"
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

resource "aws_security_group_rule" "cognoma-db-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.cognoma-db.id}"
}

resource "aws_security_group" "cognoma-db" {
  name = "cognoma-db"
  description = "cognoma-db"
  vpc_id = "${aws_vpc.cognoma-vpc.id}"

  tags {
    Name = "cognoma-db"
  }
}

resource "aws_security_group_rule" "cognoma-db-postgres-self" {
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  self = true
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

resource "aws_security_group_rule" "cognoma-db-postgres-other" {
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"

  # I'm not sure where this ip is pointing to... TBD
  cidr_blocks = ["173.161.250.209/32"]
  security_group_id = "${aws_security_group.cognoma-service.id}"
}

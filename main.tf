# You'll need to have the environment vars set to be able to do anything:
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# I suggest putting these in your .bashrc
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "cognoma-vpc" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "cognoma-1a" {
  availability_zone = "us-east-1a"
  cidr_block = "172.31.48.0/20"
  vpc_id = "${aws_vpc.cognoma-vpc.id}"
}

resource "aws_subnet" "cognoma-1b" {
  availability_zone = "us-east-1b"
  cidr_block = "172.31.0.0/20"
  vpc_id = "${aws_vpc.cognoma-vpc.id}"
  map_public_ip_on_launch = true
}

resource "aws_instance" "cognoma-service-1" {
  ami           = "ami-1924770e"
  instance_type = "t2.small"
  availability_zone = "us-east-1a"
  vpc_security_group_ids = ["${aws_security_group.cognoma-service.id}"]

  # associate_public_ip_address = "do I need this?"
}

resource "aws_instance" "cognoma-service-2" {
  ami           = "ami-1924770e"
  instance_type = "t2.small"
  availability_zone = "us-east-1b"
  vpc_security_group_ids = ["${aws_security_group.cognoma-service.id}"]
}

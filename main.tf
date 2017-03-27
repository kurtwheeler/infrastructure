# You'll need to have the environment vars set to be able to do anything:
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# I suggest putting these in your .bashrc
provider "aws" {
  region = "us-east-1"
}

variable "database_password" {}

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

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name  = "cognoma-ecs-instance-profile"
  roles = ["${aws_iam_role.ecs-instance.name}"]
}

resource "aws_iam_role" "ecs-instance" {
  name = "cognoma-ecs-instance"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_instance" "cognoma-service-1" {
  ami = "ami-1924770e"
  instance_type = "t2.small"
  availability_zone = "us-east-1a"
  vpc_security_group_ids = ["${aws_security_group.cognoma-service.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs-instance-profile.arn}"

  # associate_public_ip_address = "do I need this?"
}

resource "aws_instance" "cognoma-service-2" {
  ami = "ami-1924770e"
  instance_type = "t2.small"
  availability_zone = "us-east-1b"
  vpc_security_group_ids = ["${aws_security_group.cognoma-service.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs-instance-profile.arn}"
}

resource "aws_db_instance" "postgres-db" {
  allocated_storage = 100
  storage_type = "gp2"
  engine = "PostgreSQL"
  engine_version = "9.5.4"
  instance_class = "db.t2.large"
  name = "cognoma-postgres"
  username = "administrative"
  password = "${var.database_password}"
}

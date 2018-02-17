provider "aws" {
  region = "us-east-1"
}

variable "database_password" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
}

resource "aws_vpc" "cognoma-vpc" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "cognoma"
  }
}

resource "aws_internet_gateway" "cognoma" {
  vpc_id = "${aws_vpc.cognoma-vpc.id}"

  tags = {
    Name = "cognoma"
  }
}

resource "aws_route_table" "cognoma" {
  vpc_id = "${aws_vpc.cognoma-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.cognoma.id}"
  }

  tags {
    Name = "cognoma"
  }
}

resource "aws_subnet" "cognoma-1a" {
  availability_zone = "us-east-1a"
  cidr_block = "172.31.48.0/20"
  vpc_id = "${aws_vpc.cognoma-vpc.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "cognoma-1a"
  }
}

resource "aws_subnet" "cognoma-1b" {
  availability_zone = "us-east-1b"
  cidr_block = "172.31.0.0/20"
  vpc_id = "${aws_vpc.cognoma-vpc.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "cognoma-1b"
  }
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name  = "cognoma-ecs-instance-profile"
  role = "${aws_iam_role.ecs-instance.name}"
}

resource "aws_iam_role" "ecs-instance" {
  name = "cognoma-ecs-instance"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role = "${aws_iam_role.ecs-instance.name}"

  # The following can be found here:
  # https://console.aws.amazon.com/iam/home?region=us-east-1#/policies/arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_key_pair" "cognoma" {
  key_name = "cognoma-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC422atv4EZg9U/p+5gmIqmjV7rnlPGXt4+hqHT5Kc1zXOB8wdBBloY5ubDGPrEeG5LmxWnZ3m58N6EBa3QgyfHV+9tid0HkQCbXTeDFwelqw66D8PyCwZT2knQEks1UVCjGBQr7DDa6cE8NKypfjGvyXYRe0PuKv6ZWNm/LHBzEyXAmTx/FgsbM0CJCbjPJvCVOwElsJlwYP+V3CsZ5X+xr0rIq86oz9KJeGLfQ8gHUX14Ws0FQ6AwB+5xvuXlO2PjM3E8sNi0QI7i5+0NC+hgVq4keolJjZKgHwIi/HXPLyGSsDGgvyDnC/sbg86ckXIRh2RBL5TJk2vhinAmUXpl cognoma-instances"
}

resource "aws_instance" "cognoma-service-1" {
  ami = "ami-5e414e24"
  availability_zone = "us-east-1a"
  instance_type = "r4.large"
  vpc_security_group_ids = ["${aws_security_group.cognoma-service.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs-instance-profile.name}"
  subnet_id = "${aws_subnet.cognoma-1a.id}"
  depends_on = ["aws_internet_gateway.cognoma"]
  user_data = "${file("instance-user-data.sh")}"
  key_name = "${aws_key_pair.cognoma.key_name}"

  tags = {
    Name = "cognoma-1"
  }
}

resource "aws_instance" "cognoma-service-2" {
  ami = "ami-5e414e24"
  availability_zone = "us-east-1b"
  instance_type = "r4.large"
  vpc_security_group_ids = ["${aws_security_group.cognoma-service.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs-instance-profile.name}"
  subnet_id = "${aws_subnet.cognoma-1b.id}"
  depends_on = ["aws_internet_gateway.cognoma"]
  user_data = "${file("instance-user-data.sh")}"
  key_name = "${aws_key_pair.cognoma.key_name}"

  tags = {
    Name = "cognoma-2"
  }
}

resource "aws_db_subnet_group" "cognoma" {
  name = "cognoma"
  subnet_ids = ["${aws_subnet.cognoma-1a.id}", "${aws_subnet.cognoma-1b.id}"]

  tags {
    Name = "Cognoma DB Subnet"
  }
}

resource "aws_db_instance" "postgres-db" {
  identifier = "cognoma"
  allocated_storage = 100
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "9.5.4"
  instance_class = "db.t2.small"
  name = "cognoma_postgres"
  username = "administrator"
  password = "${var.database_password}"
  db_subnet_group_name = "${aws_db_subnet_group.cognoma.name}"
  skip_final_snapshot = true
  vpc_security_group_ids = ["${aws_security_group.cognoma-db.id}"]
  multi_az = true
}

resource "aws_iam_user" "cognoma-server" {
  name = "cognoma-server"
}

resource "aws_iam_user_policy" "ses-access" {
  name = "ses-access"
  user = "${aws_iam_user.cognoma-server.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ses:SendEmail", "ses:SendRawEmail", "ses:GetSendQuota"],
      "Resource":"*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "cognoma-server-access-key" {
  user = "${aws_iam_user.cognoma-server.name}"
}

resource "aws_iam_user" "cognoma-deployer" {
  name = "cognoma-deployer"
}

data "aws_iam_policy_document" "cognoma-deployment" {
  statement {
    actions = [
      "s3:ListObjects",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cognoma-static.id}/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cognoma-static.id}",
    ]
  }

  statement {
    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTaskDefinitions",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "cognoma-deployer" {
  name = "cognoma-deployer"
  user = "${aws_iam_user.cognoma-deployer.name}"
  policy = "${data.aws_iam_policy_document.cognoma-deployment.json}"
}

resource "aws_iam_access_key" "cognoma-deployer-access-key" {
  user = "${aws_iam_user.cognoma-deployer.name}"
}

resource "aws_s3_bucket" "cognoma-files" {
  bucket = "cognoma-files"

  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET"]
    max_age_seconds = 3000
    allowed_headers = ["Authorization"]
  }

  tags {
    Name = "Cognoma Files"
  }
}

data "aws_iam_policy_document" "cognoma-s3-access" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cognoma-files.id}/*",
    ]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cognoma-files.id}",
      "arn:aws:s3:::${aws_s3_bucket.cognoma-files.id}/*",
    ]

    principals {
      type = "AWS"
      identifiers = ["${aws_iam_user.cognoma-server.arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "cognoma-s3-policy" {
  bucket = "${aws_s3_bucket.cognoma-files.id}"
  policy = "${data.aws_iam_policy_document.cognoma-s3-access.json}"
}


resource "aws_s3_bucket" "cognoma-static" {
  bucket = "cognoma.org"

  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET"]
    max_age_seconds = 3000
    allowed_headers = ["Authorization"]
  }

  tags {
    Name = "Cognoma Static Files"
  }

  website {
    index_document = "index.html"
  }
}

data "aws_iam_policy_document" "cognoma-s3-static-access" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cognoma-static.id}/*",
    ]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "cognoma-s3-static-policy" {
  bucket = "${aws_s3_bucket.cognoma-static.id}"
  policy = "${data.aws_iam_policy_document.cognoma-s3-static-access.json}"
}

resource "aws_ecs_cluster" "cognoma" {
  name = "cognoma"
}

resource "aws_iam_role" "ecs-service-role" {
  name = "ecs-service"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "ecs-iam-role-document" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets"
    ]

    # VPCs and security groups do not have .arn attributes. The reason
    # appears to be that when specifying them in IAM policies that you
    # need to specify the region. Since this is only deployed in a
    # single region, we can actually build an "effective arn" for them.
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/${aws_security_group.cognoma-service.id}",
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/${aws_security_group.cognoma-public-elb.id}",
      "${aws_elb.cognoma-core.arn}",
      "${aws_elb.cognoma-nginx.arn}"
    ]

    condition {
      test = "StringEquals"
      variable = "ec2:Vpc"
      values = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/${aws_vpc.cognoma-vpc.id}"]
    }
  }
}

resource "aws_iam_role_policy" "ecs-service" {
  name = "ecs-service-policy"
  role = "${aws_iam_role.ecs-service-role.name}"

  policy = "${data.aws_iam_policy_document.ecs-iam-role-document.json}"
}

# ec2:Describe* cannot be limited to specfic resources:
# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ec2-api-permissions.html#ec2-api-unsupported-resource-permissions
data "aws_iam_policy_document" "ec2-describe-star" {
  statement {
    effect = "Allow"
    actions = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs-describe-ec2" {
  name = "ecs-describe-ec2"
  role = "${aws_iam_role.ecs-service-role.name}"

  policy = "${data.aws_iam_policy_document.ec2-describe-star.json}"
}

resource "aws_ecs_task_definition" "cognoma-core-service" {
  family = "cognoma-core-service"
  container_definitions = "${file("task-definitions/core-service.json.secret")}"
}

resource "aws_ecs_service" "cognoma-core-service" {
  name = "cognoma-core-service"
  cluster = "${aws_ecs_cluster.cognoma.id}"
  task_definition = "${aws_ecs_task_definition.cognoma-core-service.arn}"
  desired_count  = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 100
  iam_role = "${aws_iam_role.ecs-service-role.name}"
  depends_on = ["aws_iam_role_policy.ecs-service"]

  load_balancer {
    elb_name = "${aws_elb.cognoma-core.name}"
    container_name = "cognoma-core-service"
    container_port = 8000
  }

  # Task definitions get created during deployment. Therefore as soon
  # as someone deploys a new one, the one specified by these
  # configuration files is out of date.
  lifecycle {
    ignore_changes = ["task_definition"]
  }
}

resource "aws_ecs_task_definition" "cognoma-nginx" {
  family = "cognoma-nginx"
  container_definitions = "${file("task-definitions/nginx.json.secret")}"
}

resource "aws_ecs_service" "nginx" {
  name = "cognoma-nginx"
  cluster = "${aws_ecs_cluster.cognoma.id}"
  task_definition = "${aws_ecs_task_definition.cognoma-nginx.arn}"
  desired_count  = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 100
  iam_role = "${aws_iam_role.ecs-service-role.name}"
  depends_on = ["aws_iam_role_policy.ecs-service"]

  load_balancer {
    elb_name = "${aws_elb.cognoma-nginx.name}"
    container_name = "cognoma-nginx"
    container_port = 80
  }

  lifecycle {
    ignore_changes = ["task_definition"]
  }
}

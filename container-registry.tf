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

resource "aws_iam_role_policy" "ecs-service" {
  name = "ecs-service-policy"
  role = "${aws_iam_role.ecs-service-role.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:Describe*",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
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

resource "aws_ecr_repository" "cognoma-core-service" {
  name = "cognoma-core-service"
}

resource "aws_ecs_task_definition" "cognoma-task-service" {
  family = "cognoma-task-service"
  container_definitions = "${file("task-definitions/task-service.json.secret")}"
}

resource "aws_ecs_service" "cognoma-task-service" {
  name = "cognoma-task-service"
  cluster = "${aws_ecs_cluster.cognoma.id}"
  task_definition = "${aws_ecs_task_definition.cognoma-task-service.arn}"
  desired_count  = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 100
  iam_role = "${aws_iam_role.ecs-service-role.name}"
  depends_on = ["aws_iam_role_policy.ecs-service"]

  load_balancer {
    elb_name = "${aws_elb.cognoma-task.name}"
    container_name = "cognoma-task-service"
    container_port = 8000
  }

  # Task definitions get created during deployment. Therefore as soon
  # as someone deploys a new one, the one specified by these
  # configuration files is out of date.
  lifecycle {
    ignore_changes = ["task_definition"]
  }
}

resource "aws_ecr_repository" "cognoma-task-service" {
  name = "cognoma-task-service"
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

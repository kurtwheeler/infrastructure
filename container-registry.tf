resource "aws_iam_role" "ecs-service-role" {
  name = "ecs-service"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
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
  container_definitions = "${file("task-definitions/core-service.json.key")}"
}

resource "aws_ecs_service" "core-service" {
  name = "core-service"
  task_definition = "${aws_ecs_task_definition.cognoma-core-service.arn}"
  desired_count  = 2
  iam_role = "${aws_iam_role.ecs-service-role.name}"
  depends_on = ["aws_iam_role_policy.ecs-service"]

  load_balancer {
    elb_name = "${aws_elb.cognoma-core.name}"
    container_name = "cognoma-core-service"
    container_port = 8000
  }
}

resource "aws_ecs_task_definition" "cognoma-nginx" {
  family = "cognoma-nginx"
  container_definitions = "${file("task-definitions/nginx.json.key")}"
}

resource "aws_ecs_service" "nginx" {
  name = "cognoma-nginx"
  task_definition = "${aws_ecs_task_definition.cognoma-nginx.arn}"
  desired_count  = 2
  iam_role = "${aws_iam_role.ecs-service-role.name}"
  depends_on = ["aws_iam_role_policy.ecs-service"]

  load_balancer {
    elb_name = "${aws_elb.cognoma-nginx.name}"
    container_name = "cognoma-nginx"
    container_port = 80
  }
}

resource "aws_ecs_cluster" "cognoma" {
  name = "cognoma"
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
  iam_role = "arn:aws:iam::589864003899:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"

  # Give the service some time to come up before getting prematurely shut down.
  health_check_grace_period_seconds = 180

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

resource "aws_ecs_task_definition" "cognoma-ml-workers" {
  family = "cognoma-ml-workers"
  container_definitions = "${file("task-definitions/ml-workers.json.secret")}"
}

resource "aws_ecs_service" "cognoma-ml-workers" {
  name = "cognoma-ml-workers"
  cluster = "${aws_ecs_cluster.cognoma.id}"
  task_definition = "${aws_ecs_task_definition.cognoma-ml-workers.arn}"
  desired_count  = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 100

  # Task definitions get created during deployment. Therefore as soon
  # as someone deploys a new one, the one specified by these
  # configuration files is out of date.
  lifecycle {
    ignore_changes = ["task_definition"]
  }
}

resource "aws_ecr_repository" "cognoma-ml-workers" {
  name = "cognoma-ml-workers"
}

resource "aws_ecr_repository" "cognoma-nginx" {
  name = "cognoma-nginx"
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
  iam_role = "arn:aws:iam::589864003899:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"

  # Give the service some time to come up before getting prematurely shut down.
  health_check_grace_period_seconds = 180

  load_balancer {
    elb_name = "${aws_elb.cognoma-nginx.name}"
    container_name = "cognoma-nginx"
    container_port = 80
  }

  lifecycle {
    ignore_changes = ["task_definition"]
  }
}

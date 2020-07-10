provider "aws" {
  profile                 = "default"
  region                  = "us-west-2"
}
resource "aws_ecr_repository" "main" {
  name                = "crossfeed-worker"
  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_cluster" "fargate" {
  name = "crossfeed-worker"
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "main" {
  family                = "crossfeed-worker"
  container_definitions = file("task-definitions/service.json")
  requires_compatibilities = ["FARGATE"]
  network_mode          = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  # TODO: add these in the container definition for database credentials:
  #   "secrets": [
  #   {
  #       "name": "environment_variable_name",
  #       "valueFrom": "arn:aws:ssm:region:aws_account_id:parameter/parameter_name"
  #   }
  # ]

  # CPU and memory values: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  
  cpu = 256 # .25 vCPU
  memory = 512 # 512 MB
}

resource "aws_cloudwatch_log_group" "worker" {
  name = "crossfeed-worker" # should match awslogs-group in service.json
}


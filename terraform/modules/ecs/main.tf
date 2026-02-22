data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "this" {
  name = "ecs-${var.name}"
  tags = merge(var.tags, { Name = "ecs-${var.name}" })
}

# CloudWatch logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name}"
  retention_in_days = 14
  tags              = var.tags
}

# Execution role (pull image, write logs, fetch secrets)
resource "aws_iam_role" "execution" {
  name = "iam-ecs-exec-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "exec_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# allow execution role to read the secret
resource "aws_iam_role_policy" "exec_secrets" {
  name = "policy-ecs-secrets-${var.name}"
  role = aws_iam_role.execution.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      Resource = [var.db_secret_arn]
    }]
  })
}

# Task role (your app runtime permissions - keep minimal)
resource "aws_iam_role" "task" {
  name = "iam-ecs-task-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

# Task definition: DB_USER env + the rest from Secrets Manager JSON keys
# Note: For JSON key selection, ECS supports valueFrom like:
# arn:aws:secretsmanager:region:acct:secret:secretName-xxxx:DB_HOST::
locals {
  secret_db_host_arn     = "${var.db_secret_arn}:DB_HOST::"
  secret_db_name_arn     = "${var.db_secret_arn}:DB_NAME::"
  secret_db_password_arn = "${var.db_secret_arn}:DB_PASSWORD::"
  secret_db_port_arn     = "${var.db_secret_arn}:DB_PORT::"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "td-${var.name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name      = var.name
    image     = var.image_uri
    essential = true

    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "DB_USER", value = var.db_user }
    ]

    secrets = [
      { name = "DB_HOST",     valueFrom = local.secret_db_host_arn },
      { name = "DB_NAME",     valueFrom = local.secret_db_name_arn },
      { name = "DB_PASSWORD", valueFrom = local.secret_db_password_arn },
      { name = "DB_PORT",     valueFrom = local.secret_db_port_arn }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "app"
      }
    }
  }])

  tags = merge(var.tags, { Name = "td-${var.name}" })
}

resource "aws_ecs_service" "this" {
  name            = "svc-${var.name}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = merge(var.tags, { Name = "svc-${var.name}" })
}

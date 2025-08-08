# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# This module creates a complete Cloudflare Zero Trust deployment including:
# - Cloudflare tunnel
# - ECS cluster running cloudflared
# - IAM roles and policies
# - SSM parameter for tunnel token
# - Security groups and networking

locals {
  name_prefix = "${var.prefix}-${var.aws_region}"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Create Cloudflare tunnel
resource "cloudflare_tunnel" "main" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  secret     = random_id.tunnel_secret.b64_std
}

resource "random_id" "tunnel_secret" {
  byte_length = 32
}

# Configure tunnel routes
resource "cloudflare_tunnel_route" "routes" {
  for_each = { for idx, route in var.tunnel_routes : idx => route }

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_tunnel.main.id
  network    = each.value.network
  comment    = each.value.comment
}

# Store tunnel token in SSM Parameter Store
resource "aws_ssm_parameter" "tunnel_token" {
  name        = "/${var.prefix}/cloudflare/tunnel-token"
  description = "Cloudflare tunnel token for ${var.prefix}"
  type        = "SecureString"
  value       = cloudflare_tunnel.main.tunnel_token

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-tunnel-token"
    }
  )
}

# Create IAM role for ECS task execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.name_prefix}-cf-tunnel-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add policy to access SSM parameter
resource "aws_iam_role_policy" "ssm_access" {
  name = "${local.name_prefix}-ssm-access"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          aws_ssm_parameter.tunnel_token.arn
        ]
      }
    ]
  })
}

# Create CloudWatch log group
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${local.name_prefix}-cf-tunnel"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Create ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${local.name_prefix}-cf-tunnel-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# Configure cluster capacity providers
resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [var.fargate_type]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.fargate_type
  }
}

# Create security group for ECS tasks
resource "aws_security_group" "tunnel_sg" {
  name        = "${local.name_prefix}-cf-tunnel-sg"
  description = "Security group for Cloudflare tunnel ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic for Cloudflare tunnel"
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-cf-tunnel-sg"
    }
  )
}

# Create ECS task definition
resource "aws_ecs_task_definition" "taskdef" {
  family                   = "${local.name_prefix}-cf-tunnel"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "cloudflared"
      image     = "cloudflare/cloudflared:${var.cloudflare_version}"
      essential = true
      command   = ["tunnel", "run"]
      
      secrets = [
        {
          name      = "TUNNEL_TOKEN"
          valueFrom = aws_ssm_parameter.tunnel_token.arn
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "cloudflared"
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "cloudflared tunnel info || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = var.tags
}

# Create ECS service
resource "aws_ecs_service" "service" {
  name            = "${local.name_prefix}-cf-tunnel"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.taskdef.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = var.fargate_type
    weight            = 100
    base              = 1
  }

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.tunnel_sg.id]
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  tags = var.tags
}

# Auto-scaling target (if enabled)
resource "aws_appautoscaling_target" "ecs_target" {
  count = var.enable_auto_scaling ? 1 : 0

  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto-scaling policy - CPU utilization
resource "aws_appautoscaling_policy" "cpu_scaling" {
  count = var.enable_auto_scaling ? 1 : 0

  name               = "${local.name_prefix}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto-scaling policy - Memory utilization
resource "aws_appautoscaling_policy" "memory_scaling" {
  count = var.enable_auto_scaling ? 1 : 0

  name               = "${local.name_prefix}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}

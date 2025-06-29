# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

resource "aws_ecs_cluster" "cluster" {
  name = "${var.prefix}-cf-tunnel-cluster"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ccp" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [var.fargate_type]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.fargate_type
  }
}

resource "aws_service_discovery_private_dns_namespace" "sd_namespace" {
  name        = "${var.prefix}-sd-namespace"
  vpc         = var.vpc_id
  description = "Service discovery namespace for ${var.prefix} cluster"
}

resource "aws_service_discovery_service" "sd_service" {
  name        = "${var.prefix}-sd-service"
  namespace_id = aws_service_discovery_private_dns_namespace.sd_namespace.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.sd_namespace.id
    dns_records {
      type = "A"
      ttl  = 60
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "taskdef" {
  family                   = "${var.prefix}-cf-tunnel-taskdef"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.execution_role_arn
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions = jsonencode([
    {
      name      = "cloudflared"
      essential = true
      image     = "cloudflare/cloudflared:${var.cloudflare_version}",
      command   = ["tunnel", "run", var.tunnel_id]
      secrets = [
        {
          name      = "TUNNEL_TOKEN",
          valueFrom = var.tunnel_token_arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "cloudflared"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "${var.prefix}-cf-tunnel-logs"
  retention_in_days = 1
}

resource "aws_security_group" "tunnel_sg" {
  name        = "${var.prefix}-cf-tunnel-sg"
  description = "Security group for the ${var.prefix} Cloudflare tunnel"
  vpc_id      = var.vpc_id
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.prefix}-tunnel"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.taskdef.arn
  desired_count   = var.desired_count
  capacity_provider_strategy {
    capacity_provider = var.fargate_type
    weight            = 100
    base              = 1
  }
  network_configuration {
    subnets = var.private_subnets
    security_groups = [
      aws_security_group.tunnel_sg.id
    ]
  }
  service_registries {
    registry_arn = aws_service_discovery_service.sd_service.arn
  }
}
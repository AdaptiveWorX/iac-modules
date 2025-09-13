// Copyright (c) Adaptive Technology, LLC.
// SPDX-License-Identifier: MPL-2.0

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = var.kms_key_arn != null ? var.kms_key_arn : (length(aws_kms_key.ecs) > 0 ? aws_kms_key.ecs[0].arn : null)
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = var.kms_key_arn != null || length(aws_kms_key.ecs) > 0
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_exec.name
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "ecs_exec" {
  name              = "/aws/ecs/${var.cluster_name}/exec"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != null ? var.kms_key_arn : (length(aws_kms_key.ecs) > 0 ? aws_kms_key.ecs[0].arn : null)

  tags = merge(
    var.tags,
    {
      Name = "/aws/ecs/${var.cluster_name}/exec"
    }
  )
}

resource "aws_cloudwatch_log_group" "ecs_tasks" {
  name              = "/aws/ecs/${var.cluster_name}/tasks"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != null ? var.kms_key_arn : (length(aws_kms_key.ecs) > 0 ? aws_kms_key.ecs[0].arn : null)
  
  tags = merge(
    var.tags,
    {
      Name = "/aws/ecs/${var.cluster_name}/tasks"
    }
  )
}

# KMS Key for encryption - only created if kms_key_arn is null and create_kms_key is true
resource "aws_kms_key" "ecs" {
  count = var.kms_key_arn == null && var.create_kms_key ? 1 : 0

  description             = "ECS Encryption Key for ${var.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-key"
    }
  )
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-sg"
    }
  )
}

# Add additional security groups if provided
resource "aws_security_group_rule" "additional_egress_rules" {
  for_each = var.additional_egress_rules

  security_group_id = aws_security_group.ecs_tasks.id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# Task Execution Role - for pulling images and writing logs
resource "aws_iam_role" "task_execution_role" {
  name = "${var.cluster_name}-execution-role"

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

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role - for the task/container itself
resource "aws_iam_role" "task_role" {
  name = "${var.cluster_name}-task-role"

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

# Attach inline policies to task role if provided
resource "aws_iam_role_policy" "task_role_inline_policies" {
  for_each = var.task_role_inline_policies

  name   = each.key
  role   = aws_iam_role.task_role.name
  policy = each.value
}

# Attach managed policies to task role if provided
resource "aws_iam_role_policy_attachment" "task_role_managed_policies" {
  for_each = toset(var.task_role_managed_policy_arns)

  role       = aws_iam_role.task_role.name
  policy_arn = each.value
} 
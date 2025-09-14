# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Provider alias aws.target_account is configured in the calling module
# This allows the module to create resources in the target account

# Cross-account role in target account that trusts EC2 instances in worx-secops
resource "aws_iam_role" "cross_account_access" {
  count    = var.enable_cross_account_access ? 1 : 0
  provider = aws.target_account
  
  name = "${var.environment}-CloudflareTunnelAccess"
  path = "/cloudflare/"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.cloudflared.arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = random_password.external_id[0].result
          }
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name        = "${var.environment}-CloudflareTunnelAccess"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
    ManagedBy   = "ec2-cloudflared-module"
  })
}

# Generate external ID for secure cross-account access
resource "random_password" "external_id" {
  count   = var.enable_cross_account_access ? 1 : 0
  length  = 32
  special = false
}

# Store external ID in SSM for reference
resource "aws_ssm_parameter" "external_id" {
  count = var.enable_cross_account_access ? 1 : 0
  
  name        = "/${var.environment}/cloudflare/tunnel/external-id"
  description = "External ID for cross-account role assumption"
  type        = "SecureString"
  value       = random_password.external_id[0].result
  
  tags = merge(var.tags, {
    Name        = "${var.environment}-cf-tunnel-external-id"
    Environment = var.environment
  })
}

# Policy for cross-account role - allows access to target account resources
resource "aws_iam_role_policy" "cross_account_permissions" {
  count    = var.enable_cross_account_access ? 1 : 0
  provider = aws.target_account
  
  name = "CloudflareTunnelPermissions"
  role = aws_iam_role.cross_account_access[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDSAccess"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBProxies"
        ]
        Resource = "*"
      },
      {
        Sid    = "ELBAccess"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSAccess"
        Effect = "Allow"
        Action = [
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListTasks"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Sid    = "LogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:*:${var.target_account_id}:log-group:/cloudflare/*"
        ]
      }
    ]
  })
}

# Update the EC2 instance role to allow assuming the cross-account role
resource "aws_iam_role_policy" "assume_cross_account_role" {
  count = var.enable_cross_account_access ? 1 : 0
  
  name = "AssumeCrossAccountRole"
  role = aws_iam_role.cloudflared.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeTargetAccountRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.cross_account_access[0].arn
      }
    ]
  })
}

# Outputs are defined in outputs.tf to avoid duplication

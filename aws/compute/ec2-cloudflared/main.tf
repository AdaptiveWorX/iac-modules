# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.0"
    }
  }
}

# Data sources for networking and AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Type = "Private"
  }
}

# Security group for cloudflared tunnel
resource "aws_security_group" "cloudflared" {
  name        = "${var.name_prefix}-cloudflared-sg"
  description = "Security group for Cloudflare tunnel EC2 instance"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow HTTPS to Cloudflare"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow DNS over TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to internal resources
  egress {
    description = "Allow access to VPC resources"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-cloudflared-sg"
      Purpose     = "cloudflare-tunnel"
      Environment = var.environment
    }
  )
}

# IAM role for EC2 instance
resource "aws_iam_role" "cloudflared" {
  name               = "${var.name_prefix}-cloudflared-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-cloudflared-role"
      Purpose     = "cloudflare-tunnel"
      Environment = var.environment
    }
  )
}

# IAM role policy for SSM and CloudWatch
resource "aws_iam_role_policy" "cloudflared" {
  name = "${var.name_prefix}-cloudflared-policy"
  role = aws_iam_role.cloudflared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/cloudflare/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CloudflareTunnel"
          }
        }
      }
    ]
  })
}

# Cross-account assume role policy (if needed)
resource "aws_iam_role_policy" "cross_account" {
  count = var.enable_cross_account_access ? 1 : 0
  name  = "${var.name_prefix}-cross-account-policy"
  role  = aws_iam_role.cloudflared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for account_id in var.target_account_ids : {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:aws:iam::${account_id}:role/CloudflareTunnelAccess"
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "cloudflared" {
  name = "${var.name_prefix}-cloudflared-profile"
  role = aws_iam_role.cloudflared.name
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# User data script for cloudflared installation and configuration
locals {
  user_data_script = templatefile("${path.module}/user-data.sh", {
    environment          = var.environment
    tunnel_token        = var.tunnel_token_parameter
    tunnel_name         = var.tunnel_name
    region              = var.region
    cloudflared_version = var.cloudflared_version
    log_group_name      = aws_cloudwatch_log_group.cloudflared.name
    tunnel_routes       = jsonencode(var.tunnel_routes)
    metrics_interval    = var.metrics_interval
  })
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "cloudflared" {
  name              = "/aws/ec2/cloudflared/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "/aws/ec2/cloudflared/${var.environment}"
      Purpose     = "cloudflare-tunnel"
      Environment = var.environment
    }
  )
}

# EC2 instance for cloudflared
resource "aws_instance" "cloudflared" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id != "" ? var.subnet_id : data.aws_subnets.private.ids[0]
  vpc_security_group_ids = [aws_security_group.cloudflared.id]
  iam_instance_profile   = aws_iam_instance_profile.cloudflared.name
  
  user_data                   = base64encode(local.user_data_script)
  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-cloudflared"
      Purpose     = "cloudflare-tunnel"
      Environment = var.environment
      Tunnel      = var.tunnel_name
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes       = [ami]
  }
}

# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "${var.name_prefix}-cloudflared-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors ec2 status check"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.cloudflared.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-cloudflared-status-check"
      Purpose     = "cloudflare-tunnel"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.name_prefix}-cloudflared-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.cloudflared.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-cloudflared-high-cpu"
      Purpose     = "cloudflare-tunnel"
      Environment = var.environment
    }
  )
}

# Auto-recovery for instance failures
resource "aws_cloudwatch_metric_alarm" "auto_recovery" {
  alarm_name          = "${var.name_prefix}-cloudflared-auto-recovery"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "0"
  alarm_description   = "Trigger auto-recovery when instance fails system status checks"
  
  alarm_actions = concat(
    ["arn:aws:automate:${var.region}:ec2:recover"],
    var.alarm_actions
  )

  dimensions = {
    InstanceId = aws_instance.cloudflared.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-cloudflared-auto-recovery"
      Purpose     = "cloudflare-tunnel"
      Environment = var.environment
    }
  )
}

# Optional: Create SSM Parameter for tunnel status
resource "aws_ssm_parameter" "tunnel_status" {
  count = var.create_status_parameter ? 1 : 0
  
  name  = "/${var.environment}/cloudflare/tunnel/${var.tunnel_name}/status"
  type  = "String"
  value = jsonencode({
    instance_id = aws_instance.cloudflared.id
    private_ip  = aws_instance.cloudflared.private_ip
    subnet_id   = aws_instance.cloudflared.subnet_id
    created_at  = timestamp()
    environment = var.environment
    tunnel_name = var.tunnel_name
  })

  tags = merge(
    var.tags,
    {
      Name        = "/${var.environment}/cloudflare/tunnel/${var.tunnel_name}/status"
      Purpose     = "cloudflare-tunnel"
      Environment = var.environment
    }
  )
}

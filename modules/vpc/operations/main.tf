# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Operations Module - Operations Layer
# Consolidates: monitoring, flow logs, and operational tools
# This layer contains resources that change frequently

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9"
    }
  }
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ============================================================================
# DATA SOURCES - Reference Foundation Layer
# ============================================================================

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get NAT Gateway IDs from the foundation layer
data "aws_nat_gateways" "main" {
  vpc_id = data.aws_vpc.main.id
}

data "aws_nat_gateway" "main" {
  count = length(data.aws_nat_gateways.main.ids)
  id    = data.aws_nat_gateways.main.ids[count.index]
}

locals {
  vpc_id   = data.aws_vpc.main.id
  vpc_cidr = data.aws_vpc.main.cidr_block
  
  flow_log_name  = "${var.environment}-vpc-flow-logs"
  current_region = data.aws_region.current.id
  account_id     = data.aws_caller_identity.current.account_id
  
  nat_gateway_ids = data.aws_nat_gateways.main.ids
}

# ============================================================================
# VPC FLOW LOGS
# ============================================================================

# S3 bucket for VPC Flow Logs
resource "aws_s3_bucket" "flow_logs" {
  count         = var.enable_flow_logs && var.flow_log_destination == "s3" ? 1 : 0
  bucket        = "${var.environment}-vpc-flow-logs-${local.current_region}-${local.account_id}"
  force_destroy = var.flow_logs_force_destroy

  tags = merge(
    var.tags,
    {
      Name        = "${local.flow_log_name}-${local.current_region}"
      Environment = var.environment
      Purpose     = "VPC Flow Logs Storage"
      ManagedBy   = "terraform"
    }
  )
}

# S3 bucket lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count  = var.enable_flow_logs && var.flow_log_destination == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.flow_logs_retention_days
    }
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [rule]
  }
  
  depends_on = [aws_s3_bucket.flow_logs]
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count  = var.enable_flow_logs && var.flow_log_destination == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count  = var.enable_flow_logs && var.flow_log_destination == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs && var.flow_log_destination == "cloudwatch" ? 1 : 0
  name              = "/aws/vpc/${local.flow_log_name}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    var.tags,
    {
      Name        = local.flow_log_name
      Environment = var.environment
      Purpose     = "VPC Flow Logs"
      ManagedBy   = "terraform"
    }
  )
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.environment}-vpc-flow-logs-role-${local.current_region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-vpc-flow-logs-role-${local.current_region}"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "flow_logs_cloudwatch" {
  count = var.enable_flow_logs && var.flow_log_destination == "cloudwatch" ? 1 : 0
  name  = "vpc-flow-logs-cloudwatch"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for S3
resource "aws_iam_role_policy" "flow_logs_s3" {
  count = var.enable_flow_logs && var.flow_log_destination == "s3" ? 1 : 0
  name  = "vpc-flow-logs-s3"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.flow_logs[0].arn,
          "${aws_s3_bucket.flow_logs[0].arn}/*"
        ]
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "vpc" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn             = var.flow_log_destination == "cloudwatch" ? aws_iam_role.flow_logs[0].arn : null
  log_destination_type     = var.flow_log_destination
  log_destination          = var.flow_log_destination == "s3" ? aws_s3_bucket.flow_logs[0].arn : aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type             = var.flow_log_traffic_type
  vpc_id                   = local.vpc_id
  max_aggregation_interval = var.flow_log_aggregation_interval

  tags = merge(
    var.tags,
    {
      Name        = local.flow_log_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ============================================================================
# MONITORING AND ALARMS
# ============================================================================

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  count = var.enable_monitoring_alarms ? 1 : 0
  name  = "${var.environment}-vpc-alarms"

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-vpc-alarms"
      Environment = var.environment
      Purpose     = "VPC Monitoring Alarms"
      ManagedBy   = "terraform"
    }
  )
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.enable_monitoring_alarms && var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Alarm for NAT Gateway Bandwidth
resource "aws_cloudwatch_metric_alarm" "nat_gateway_bandwidth" {
  count = var.enable_monitoring_alarms ? length(local.nat_gateway_ids) : 0

  alarm_name          = "${var.environment}-nat-gateway-${count.index + 1}-high-bandwidth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BytesOutToDestination"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.nat_gateway_bandwidth_threshold_bytes
  alarm_description   = "NAT Gateway ${count.index + 1} bandwidth usage is high"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    NatGatewayId = local.nat_gateway_ids[count.index]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nat-gateway-${count.index + 1}-bandwidth-alarm"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# CloudWatch Alarm for NAT Gateway Error Port Allocation
resource "aws_cloudwatch_metric_alarm" "nat_gateway_error_port_allocation" {
  count = var.enable_monitoring_alarms ? length(local.nat_gateway_ids) : 0

  alarm_name          = "${var.environment}-nat-gateway-${count.index + 1}-port-allocation-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "NAT Gateway ${count.index + 1} port allocation errors detected"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    NatGatewayId = local.nat_gateway_ids[count.index]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nat-gateway-${count.index + 1}-port-allocation-alarm"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ============================================================================
# CLOUDWATCH DASHBOARD
# ============================================================================

resource "aws_cloudwatch_dashboard" "vpc" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = "${var.environment}-vpc-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title   = "NAT Gateway Bandwidth"
          region  = local.current_region
          view    = "timeSeries"
          stacked = false
          metrics = [
            for idx, nat_id in local.nat_gateway_ids : [
              "AWS/EC2",
              "BytesOutToDestination",
              { NatGatewayId = nat_id },
              { label = "NAT Gateway ${idx + 1}" }
            ]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = {
              label = "Bytes"
              min   = 0
            }
          }
        }
        width  = 12
        height = 6
      },
      {
        type = "metric"
        properties = {
          title   = "NAT Gateway Connection Count"
          region  = local.current_region
          view    = "timeSeries"
          stacked = false
          metrics = [
            for idx, nat_id in local.nat_gateway_ids : [
              "AWS/EC2",
              "ActiveConnectionCount",
              { NatGatewayId = nat_id },
              { label = "NAT Gateway ${idx + 1}" }
            ]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = {
              label = "Count"
              min   = 0
            }
          }
        }
        width  = 12
        height = 6
      },
      {
        type = "metric"
        properties = {
          title   = "VPC Flow Logs Records"
          region  = local.current_region
          view    = "singleValue"
          metrics = var.enable_flow_logs && var.flow_log_destination == "cloudwatch" ? [
            [
              "AWS/Logs",
              "IncomingLogEvents",
              { LogGroupName = "/aws/vpc/${local.flow_log_name}" }
            ]
          ] : []
          period = 300
          stat   = "Sum"
        }
        width  = 6
        height = 3
      }
    ]
  })
}

# ============================================================================
# COST ANALYSIS (OPTIONAL)
# ============================================================================

resource "aws_ce_cost_allocation_tag" "vpc" {
  count = var.enable_cost_allocation_tags ? 1 : 0

  tag_key = "Environment"
  status  = "Active"
}

resource "aws_ce_cost_allocation_tag" "vpc_name" {
  count = var.enable_cost_allocation_tags ? 1 : 0

  tag_key = "Name"
  status  = "Active"
}

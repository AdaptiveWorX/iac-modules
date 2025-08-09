# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Monitoring Module - Flow Logs and CloudWatch Alarms

locals {
  flow_log_name = "${var.environment}-vpc-flow-logs"
  # Use data.aws_region.current.id instead of deprecated .name
  current_region = data.aws_region.current.id
}

# Data source for current region
data "aws_region" "current" {}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# S3 bucket for VPC Flow Logs
resource "aws_s3_bucket" "flow_logs" {
  count         = var.enable_flow_logs && var.flow_log_destination == "s3" ? 1 : 0
  bucket        = "${var.environment}-vpc-flow-logs-${local.current_region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true  # Allow bucket deletion even when not empty

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

    # Apply to all objects in the bucket
    filter {}

    expiration {
      days = var.flow_logs_retention_days
    }
  }

  # Lifecycle block to handle destroy-time issues
  lifecycle {
    create_before_destroy = false
    ignore_changes = [rule]
  }
  
  # Ensure the bucket exists before creating lifecycle configuration
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
  vpc_id                   = var.vpc_id
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
  count     = var.enable_monitoring_alarms ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Alarm for NAT Gateway Bandwidth
resource "aws_cloudwatch_metric_alarm" "nat_gateway_bandwidth" {
  count = var.enable_monitoring_alarms ? length(var.nat_gateway_ids) : 0

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
    NatGatewayId = var.nat_gateway_ids[count.index]
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
  count = var.enable_monitoring_alarms ? length(var.nat_gateway_ids) : 0

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
    NatGatewayId = var.nat_gateway_ids[count.index]
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

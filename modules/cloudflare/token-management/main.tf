# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module for managing Cloudflare API tokens in AWS Secrets Manager

locals {
  token_prefix = var.token_prefix != "" ? "${var.token_prefix}/" : ""
}

# Store Cloudflare API tokens in Secrets Manager
resource "aws_secretsmanager_secret" "cloudflare_tokens" {
  for_each = var.tokens

  name        = "${local.token_prefix}cloudflare/api-token/${each.key}"
  description = each.value.description

  # Enable automatic rotation if specified
  dynamic "rotation_rules" {
    for_each = var.enable_rotation ? [1] : []
    content {
      automatically_after_days = var.rotation_days
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.token_prefix}cloudflare-token-${each.key}"
      Purpose     = each.value.purpose
      Environment = each.value.environment
      ManagedBy   = "terraform"
    }
  )
}

# Store the actual token values
resource "aws_secretsmanager_secret_version" "cloudflare_tokens" {
  for_each = var.tokens

  secret_id     = aws_secretsmanager_secret.cloudflare_tokens[each.key].id
  secret_string = each.value.token_value

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# IAM policy for reading tokens
resource "aws_iam_policy" "read_tokens" {
  name        = "${var.token_prefix}cloudflare-token-read-policy"
  description = "Policy to read Cloudflare API tokens from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          for secret in aws_secretsmanager_secret.cloudflare_tokens : secret.arn
        ]
      }
    ]
  })

  tags = var.tags
}

# IAM policy for managing tokens (for rotation)
resource "aws_iam_policy" "manage_tokens" {
  count = var.enable_rotation ? 1 : 0

  name        = "${var.token_prefix}cloudflare-token-manage-policy"
  description = "Policy to manage Cloudflare API tokens in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecret",
          "secretsmanager:RotateSecret",
          "secretsmanager:PutSecretValue"
        ]
        Resource = [
          for secret in aws_secretsmanager_secret.cloudflare_tokens : secret.arn
        ]
      }
    ]
  })

  tags = var.tags
}

# CloudWatch alarms for token expiration
resource "aws_cloudwatch_metric_alarm" "token_expiration" {
  for_each = var.enable_expiration_alerts ? var.tokens : {}

  alarm_name          = "${var.token_prefix}cloudflare-token-${each.key}-expiration"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DaysUntilExpiration"
  namespace           = "CloudflareTokens"
  period              = "86400"
  statistic           = "Average"
  threshold           = var.alert_days_before_expiry
  alarm_description   = "Alert when Cloudflare token ${each.key} is near expiration"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = var.tags
}

# Lambda function for token rotation (optional)
resource "aws_lambda_function" "token_rotator" {
  count = var.enable_automatic_rotation ? 1 : 0

  filename         = "${path.module}/lambda/token_rotator.zip"
  function_name    = "${var.token_prefix}cloudflare-token-rotator"
  role            = aws_iam_role.lambda_rotator[0].arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 256

  environment {
    variables = {
      CLOUDFLARE_ACCOUNT_ID = var.cloudflare_account_id
      TOKEN_PREFIX          = local.token_prefix
      SNS_TOPIC_ARN        = var.sns_topic_arn
    }
  }

  tags = var.tags
}

# IAM role for Lambda rotator
resource "aws_iam_role" "lambda_rotator" {
  count = var.enable_automatic_rotation ? 1 : 0

  name = "${var.token_prefix}cloudflare-token-rotator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach policies to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = var.enable_automatic_rotation ? 1 : 0

  role       = aws_iam_role.lambda_rotator[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  count = var.enable_automatic_rotation ? 1 : 0

  role       = aws_iam_role.lambda_rotator[0].name
  policy_arn = aws_iam_policy.manage_tokens[0].arn
}

# EventBridge rule for scheduled rotation
resource "aws_cloudwatch_event_rule" "rotation_schedule" {
  count = var.enable_automatic_rotation ? 1 : 0

  name                = "${var.token_prefix}cloudflare-token-rotation"
  description         = "Trigger Cloudflare token rotation"
  schedule_expression = "rate(${var.rotation_check_days} days)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "rotation_lambda" {
  count = var.enable_automatic_rotation ? 1 : 0

  rule      = aws_cloudwatch_event_rule.rotation_schedule[0].name
  target_id = "TokenRotatorLambda"
  arn       = aws_lambda_function.token_rotator[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count = var.enable_automatic_rotation ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.token_rotator[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotation_schedule[0].arn
}

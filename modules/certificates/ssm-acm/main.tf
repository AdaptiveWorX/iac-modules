# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module: certificates/ssm-acm
# Purpose: Import certificates from SSM Parameter Store to ACM

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
      configuration_aliases = [aws.secops]
    }
  }
}

# Fetch certificates from SSM Parameter Store in worx-secops account
data "aws_ssm_parameter" "certificate" {
  provider = aws.secops
  name     = "/certificates/multi-domain/certificate"
}

data "aws_ssm_parameter" "private_key" {
  provider        = aws.secops
  name            = "/certificates/multi-domain/private-key"
  with_decryption = true
}

data "aws_ssm_parameter" "chain" {
  provider = aws.secops
  name     = "/certificates/multi-domain/chain"
}

data "aws_ssm_parameter" "expiry" {
  provider = aws.secops
  name     = "/certificates/multi-domain/expiry"
}

# Import certificate to ACM in the current region
resource "aws_acm_certificate" "multi_domain" {
  certificate_body  = data.aws_ssm_parameter.certificate.value
  private_key       = data.aws_ssm_parameter.private_key.value
  certificate_chain = data.aws_ssm_parameter.chain.value

  tags = merge(var.common_tags, {
    Name       = "multi-domain-wildcard"
    Expiry     = data.aws_ssm_parameter.expiry.value
    Purpose    = "regional"
    Region     = var.aws_region
    ManagedBy  = "terragrunt"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFront certificate (only in us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  count = var.deploy_cloudfront_cert ? 1 : 0
  
  certificate_body  = data.aws_ssm_parameter.certificate.value
  private_key       = data.aws_ssm_parameter.private_key.value
  certificate_chain = data.aws_ssm_parameter.chain.value

  tags = merge(var.common_tags, {
    Name       = "multi-domain-wildcard-cloudfront"
    Expiry     = data.aws_ssm_parameter.expiry.value
    Purpose    = "cloudfront"
    ManagedBy  = "terragrunt"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EventBridge rule for ACM certificate expiration notifications
resource "aws_cloudwatch_event_rule" "acm_expiry" {
  name        = "acm-certificate-expiry-${var.environment}"
  description = "Capture ACM certificate expiry events"

  event_pattern = jsonencode({
    source      = ["aws.acm"]
    detail-type = ["ACM Certificate Approaching Expiration"]
    detail = {
      CertificateArn = [
        { prefix = "arn:aws:acm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:certificate/" }
      ]
    }
  })

  tags = merge(var.common_tags, {
    Name = "acm-expiry-rule"
  })
}

# SNS topic for certificate expiry alerts
resource "aws_sns_topic" "certificate_alerts" {
  name = "certificate-expiry-alerts-${var.aws_region}"

  tags = merge(var.common_tags, {
    Name = "certificate-expiry-alerts"
  })
}

# SNS topic policy to allow EventBridge to publish
resource "aws_sns_topic_policy" "certificate_alerts" {
  arn = aws_sns_topic.certificate_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.certificate_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# EventBridge target to send notifications to SNS
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.acm_expiry.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.certificate_alerts.arn
}

# Email subscription for alerts
resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.certificate_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Get current account ID
data "aws_caller_identity" "current" {}

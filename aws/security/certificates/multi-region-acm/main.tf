# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module: certificates/multi-region-acm
# Purpose: Deploy certificates to all enabled regions dynamically based on regions.yaml

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

# Get current account ID
data "aws_caller_identity" "current" {}

# Import certificate to ACM in each enabled region
# This will be called from a wrapper that handles the regional providers
resource "aws_acm_certificate" "multi_domain" {
  certificate_body  = data.aws_ssm_parameter.certificate.value
  private_key       = data.aws_ssm_parameter.private_key.value
  certificate_chain = data.aws_ssm_parameter.chain.value

  tags = merge(var.common_tags, {
    Name            = "multi-domain-wildcard"
    Expiry          = data.aws_ssm_parameter.expiry.value
    Purpose         = var.purpose
    Region          = var.aws_region
    Provider        = "Sectigo"
    HIPAA_Compliant = "true"
    ManagedBy       = "terragrunt"
    LastUpdated     = timestamp()
  })

  lifecycle {
    # IMPORTANT: Set to false to preserve ARNs during certificate updates
    # This enables in-place updates when certificate content changes
    create_before_destroy = false
    
    # Ignore changes that are managed externally
    ignore_changes = [
      tags["LastUpdated"],
    ]
  }
}

# CloudWatch Event Rule for certificate expiry notifications (us-east-1 only)
resource "aws_cloudwatch_event_rule" "acm_expiry" {
  count = var.aws_region == "us-east-1" && var.environment != "" ? 1 : 0
  
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

# SNS topic for alerts (us-east-1 only)
resource "aws_sns_topic" "certificate_alerts" {
  count = var.aws_region == "us-east-1" && var.environment != "" && var.alert_email != "" ? 1 : 0
  
  name = "certificate-expiry-alerts-${var.environment}"

  tags = merge(var.common_tags, {
    Name = "certificate-expiry-alerts"
  })
}

# SNS subscription for email alerts
resource "aws_sns_topic_subscription" "email" {
  count = var.aws_region == "us-east-1" && var.environment != "" && var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.certificate_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# EventBridge target to send notifications to SNS
resource "aws_cloudwatch_event_target" "sns" {
  count = var.aws_region == "us-east-1" && var.environment != "" && var.alert_email != "" ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.acm_expiry[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.certificate_alerts[0].arn
}

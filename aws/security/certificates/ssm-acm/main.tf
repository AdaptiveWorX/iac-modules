# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module: certificates/ssm-acm
# Purpose: Import certificates from SSM Parameter Store to ACM with in-place update support

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
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

# Get SSM parameter versions to track changes (optional - may not exist)
data "aws_ssm_parameter" "certificate_version" {
  count    = var.enable_certificate_versioning ? 1 : 0
  provider = aws.secops
  name     = "/certificates/multi-domain/certificate-version"
}

# Import certificate to ACM in the current region
# This resource supports in-place updates when certificate content changes
resource "aws_acm_certificate" "multi_domain" {
  certificate_body  = data.aws_ssm_parameter.certificate.value
  private_key       = data.aws_ssm_parameter.private_key.value
  certificate_chain = data.aws_ssm_parameter.chain.value

  tags = merge(var.common_tags, {
    Name           = "multi-domain-wildcard"
    Expiry         = data.aws_ssm_parameter.expiry.value
    Purpose        = "regional"
    Region         = var.aws_region
    ManagedBy      = "terragrunt"
    CertVersion    = var.enable_certificate_versioning && length(data.aws_ssm_parameter.certificate_version) > 0 ? data.aws_ssm_parameter.certificate_version[0].value : "1"
    LastUpdated    = timestamp()
    UpdateBehavior = var.certificate_update_behavior
  })

  lifecycle {
    # CRITICAL FOR ZERO DOWNTIME: Set to false to preserve ARNs
    # This enables in-place updates when certificate content changes
    # ACM will update the certificate without changing the ARN
    create_before_destroy = false

    # Ignore tag changes that are managed externally
    ignore_changes = [
      tags["LastUpdated"],
    ]
  }
}

# CloudFront certificate (only in us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  count = var.deploy_cloudfront_cert ? 1 : 0

  certificate_body  = data.aws_ssm_parameter.certificate.value
  private_key       = data.aws_ssm_parameter.private_key.value
  certificate_chain = data.aws_ssm_parameter.chain.value

  tags = merge(var.common_tags, {
    Name           = "multi-domain-wildcard-cloudfront"
    Expiry         = data.aws_ssm_parameter.expiry.value
    Purpose        = "cloudfront"
    ManagedBy      = "terragrunt"
    CertVersion    = var.enable_certificate_versioning && length(data.aws_ssm_parameter.certificate_version) > 0 ? data.aws_ssm_parameter.certificate_version[0].value : "1"
    LastUpdated    = timestamp()
    UpdateBehavior = var.certificate_update_behavior
  })

  lifecycle {
    # CRITICAL FOR ZERO DOWNTIME: Preserve ARN for CloudFront distributions
    create_before_destroy = false

    ignore_changes = [
      tags["LastUpdated"],
    ]
  }
}

# Null resource to handle certificate reimport logic
# This ensures proper reimport when SSM parameters change
resource "null_resource" "certificate_reimport_trigger" {
  triggers = {
    certificate_hash = sha256("${data.aws_ssm_parameter.certificate.value}${data.aws_ssm_parameter.private_key.value}${data.aws_ssm_parameter.chain.value}")
    update_behavior  = var.certificate_update_behavior
  }

  provisioner "local-exec" {
    when    = create
    command = "echo 'Certificate content changed, triggering update...'"
  }
}

# EventBridge rule for ACM certificate expiration notifications
# Only create in us-east-1 since all regions use the same certificate
resource "aws_cloudwatch_event_rule" "acm_expiry" {
  count = var.aws_region == "us-east-1" ? 1 : 0

  name        = "acm-certificate-expiry-${var.environment}"
  description = "Capture ACM certificate expiry events (centralized in us-east-1)"

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
    Note = "Centralized monitoring in us-east-1 only"
  })
}

# SNS topic for certificate expiry alerts
# Only create in us-east-1 to avoid duplicate notifications
resource "aws_sns_topic" "certificate_alerts" {
  count = var.aws_region == "us-east-1" ? 1 : 0

  name = "certificate-expiry-alerts-${var.environment}"

  tags = merge(var.common_tags, {
    Name = "certificate-expiry-alerts"
    Note = "Centralized alerts for all regions"
  })
}

# SNS topic policy to allow EventBridge to publish
resource "aws_sns_topic_policy" "certificate_alerts" {
  count = var.aws_region == "us-east-1" ? 1 : 0

  arn = aws_sns_topic.certificate_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.certificate_alerts[0].arn
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
  count = var.aws_region == "us-east-1" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.acm_expiry[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.certificate_alerts[0].arn
}

# Email subscription for alerts
resource "aws_sns_topic_subscription" "email" {
  count = var.aws_region == "us-east-1" && var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.certificate_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Get current account ID
data "aws_caller_identity" "current" {}

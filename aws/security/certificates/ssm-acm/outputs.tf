# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module: certificates/ssm-acm
# Purpose: Outputs for SSM to ACM certificate import module

output "certificate_arn" {
  description = "ARN of the imported ACM certificate"
  value       = aws_acm_certificate.multi_domain.arn
  sensitive   = true
}

output "certificate_id" {
  description = "ID of the imported ACM certificate"
  value       = aws_acm_certificate.multi_domain.id
  sensitive   = true
}

output "certificate_domain_name" {
  description = "Domain name of the imported certificate"
  value       = aws_acm_certificate.multi_domain.domain_name
}

output "certificate_status" {
  description = "Status of the imported certificate"
  value       = aws_acm_certificate.multi_domain.status
}

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront certificate (if deployed)"
  value       = try(aws_acm_certificate.cloudfront[0].arn, null)
  sensitive   = true
}

output "cloudfront_certificate_id" {
  description = "ID of the CloudFront certificate (if deployed)"
  value       = try(aws_acm_certificate.cloudfront[0].id, null)
  sensitive   = true
}

output "certificate_expiry" {
  description = "Expiry date of the certificate from SSM"
  value       = data.aws_ssm_parameter.expiry.value
  sensitive   = true
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for certificate expiry alerts (only in us-east-1)"
  value       = try(aws_sns_topic.certificate_alerts[0].arn, null)
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule for ACM expiry notifications (only in us-east-1)"
  value       = try(aws_cloudwatch_event_rule.acm_expiry[0].arn, null)
}

output "certificate_details" {
  description = "Map of certificate details"
  value = {
    arn         = aws_acm_certificate.multi_domain.arn
    domain_name = aws_acm_certificate.multi_domain.domain_name
    status      = aws_acm_certificate.multi_domain.status
    expiry      = data.aws_ssm_parameter.expiry.value
    region      = var.aws_region
  }
  sensitive = true
}

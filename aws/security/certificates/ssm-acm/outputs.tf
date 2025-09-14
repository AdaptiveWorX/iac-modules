# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "certificate_arn" {
  description = "ARN of the imported ACM certificate"
  value       = aws_acm_certificate.multi_domain.arn
}

output "certificate_domain_name" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.multi_domain.domain_name
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate.multi_domain.status
}

output "certificate_expiry" {
  description = "Certificate expiration date from SSM"
  value       = data.aws_ssm_parameter.expiry.value
  sensitive   = true  # Mark as sensitive since it comes from SSM
}

output "certificate_version" {
  description = "Certificate version identifier"
  value       = var.enable_certificate_versioning && length(data.aws_ssm_parameter.certificate_version) > 0 ? data.aws_ssm_parameter.certificate_version[0].value : "unknown"
}

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront certificate (if deployed)"
  value       = try(aws_acm_certificate.cloudfront[0].arn, null)
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for certificate alerts"
  value       = try(aws_sns_topic.certificate_alerts[0].arn, null)
}

output "certificate_update_behavior" {
  description = "Current certificate update behavior setting"
  value       = var.certificate_update_behavior
}

output "certificate_hash" {
  description = "Hash of current certificate content for change detection"
  value       = null_resource.certificate_reimport_trigger.triggers.certificate_hash
  sensitive   = true
}

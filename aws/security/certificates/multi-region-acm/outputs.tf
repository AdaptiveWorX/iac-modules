# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "certificate_arn" {
  value       = aws_acm_certificate.multi_domain.arn
  description = "ARN of the imported ACM certificate"
}

output "certificate_id" {
  value       = aws_acm_certificate.multi_domain.id
  description = "ID of the imported ACM certificate"
}

output "certificate_domain_name" {
  value       = aws_acm_certificate.multi_domain.domain_name
  description = "Domain name associated with the certificate"
}

output "certificate_status" {
  value       = aws_acm_certificate.multi_domain.status
  description = "Status of the certificate"
}

output "certificate_expiry" {
  value       = data.aws_ssm_parameter.expiry.value
  description = "Certificate expiry date from SSM"
}

output "sns_topic_arn" {
  value       = length(aws_sns_topic.certificate_alerts) > 0 ? aws_sns_topic.certificate_alerts[0].arn : null
  description = "ARN of the SNS topic for certificate alerts (if created)"
}

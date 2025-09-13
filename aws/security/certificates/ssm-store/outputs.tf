# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module: certificates/ssm-store
# Purpose: Outputs for SSM certificate storage module

output "certificate_parameter_arn" {
  description = "ARN of the SSM parameter storing the certificate body"
  value       = aws_ssm_parameter.certificate.arn
}

output "private_key_parameter_arn" {
  description = "ARN of the SSM parameter storing the private key"
  value       = aws_ssm_parameter.private_key.arn
  sensitive   = true
}

output "chain_parameter_arn" {
  description = "ARN of the SSM parameter storing the certificate chain"
  value       = aws_ssm_parameter.chain.arn
}

output "expiry_parameter_arn" {
  description = "ARN of the SSM parameter storing the expiry date"
  value       = aws_ssm_parameter.expiry.arn
}

output "certificate_reader_role_arn" {
  description = "ARN of the IAM role for cross-account certificate access"
  value       = aws_iam_role.certificate_reader.arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for private key encryption"
  value       = aws_kms_key.certificate_key.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for private key encryption"
  value       = aws_kms_key.certificate_key.arn
}

output "parameter_paths" {
  description = "Map of SSM parameter paths for certificate components"
  value = {
    certificate = "/certificates/multi-domain/certificate"
    private_key = "/certificates/multi-domain/private-key"
    chain       = "/certificates/multi-domain/chain"
    expiry      = "/certificates/multi-domain/expiry"
  }
}

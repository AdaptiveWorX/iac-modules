# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

output "token_name" {
  description = "The name of the SSM token."
  value       = aws_ssm_parameter.tunneltoken.name
}

output "tunnel_token_arn" {
  description = "The ARN of the SSM token."
  value       = aws_ssm_parameter.tunneltoken.arn
}
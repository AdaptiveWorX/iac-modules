# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "secret_arns" {
  description = "ARNs of the created secrets"
  value = {
    for key, secret in aws_secretsmanager_secret.cloudflare_tokens : 
    key => secret.arn
  }
}

output "secret_names" {
  description = "Names of the created secrets"
  value = {
    for key, secret in aws_secretsmanager_secret.cloudflare_tokens : 
    key => secret.name
  }
}

output "read_policy_arn" {
  description = "ARN of the IAM policy for reading tokens"
  value       = aws_iam_policy.read_tokens.arn
}

output "manage_policy_arn" {
  description = "ARN of the IAM policy for managing tokens"
  value       = var.enable_rotation ? aws_iam_policy.manage_tokens[0].arn : null
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function for token rotation"
  value       = var.enable_automatic_rotation ? aws_lambda_function.token_rotator[0].arn : null
}

output "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda rotation"
  value       = var.enable_automatic_rotation ? aws_iam_role.lambda_rotator[0].arn : null
}

# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

output "tunnel_role_arn" {
  description = "ARN of the Cloudflare Tunnel ECS execution role."
  value       = aws_iam_role.executionrole.arn
}
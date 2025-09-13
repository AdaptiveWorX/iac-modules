# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "tunnel_id" {
  description = "ID of the created Cloudflare tunnel"
  value       = cloudflare_tunnel.main.id
}

output "tunnel_name" {
  description = "Name of the created Cloudflare tunnel"
  value       = cloudflare_tunnel.main.name
}

output "tunnel_cname" {
  description = "CNAME value for the tunnel"
  value       = cloudflare_tunnel.main.cname
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.cluster.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.cluster.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "security_group_id" {
  description = "ID of the security group for the tunnel"
  value       = aws_security_group.tunnel_sg.id
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.logs.name
}

output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ssm_parameter_name" {
  description = "Name of the SSM parameter storing the tunnel token"
  value       = aws_ssm_parameter.tunnel_token.name
}

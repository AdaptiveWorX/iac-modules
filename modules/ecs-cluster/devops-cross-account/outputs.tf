// Copyright (c) Adaptive Technology, LLC.
// SPDX-License-Identifier: MPL-2.0

output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.task_execution_role.arn
}

output "task_execution_role_name" {
  description = "The name of the ECS task execution role"
  value       = aws_iam_role.task_execution_role.name
}

output "task_role_arn" {
  description = "The ARN of the ECS task role"
  value       = aws_iam_role.task_role.arn
}

output "task_role_name" {
  description = "The name of the ECS task role"
  value       = aws_iam_role.task_role.name
}

output "security_group_id" {
  description = "The ID of the security group for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "log_group_name" {
  description = "The name of the CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs_tasks.name
} 
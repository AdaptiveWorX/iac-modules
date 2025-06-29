# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "ecs_service_id" {
  value = aws_ecs_service.ecs_service.id
}

output "sd_service_name" {
  value = aws_service_discovery_service.sd_service.name 
}

output "tunnel_sg_id" {
  value = aws_security_group.tunnel_sg.id
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.logs.name
}
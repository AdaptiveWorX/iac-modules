# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Endpoints Module Outputs

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC endpoint for use in security groups"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "dynamodb_endpoint_prefix_list_id" {
  description = "Prefix list ID of the DynamoDB VPC endpoint for use in security groups"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].prefix_list_id : null
}

output "interface_endpoint_ids" {
  description = "Map of interface endpoint service names to their IDs"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_dns_names" {
  description = "Map of interface endpoint service names to their DNS names"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.dns_entry[0].dns_name }
}

output "endpoints_security_group_id" {
  description = "Security group ID for interface endpoints"
  value       = length(var.interface_endpoints) > 0 ? aws_security_group.endpoints[0].id : null
}

output "gateway_endpoints" {
  description = "List of gateway endpoints created"
  value = compact([
    "s3",
    var.enable_dynamodb_endpoint ? "dynamodb" : ""
  ])
}

output "interface_endpoints_list" {
  description = "List of interface endpoints created"
  value       = var.interface_endpoints
}

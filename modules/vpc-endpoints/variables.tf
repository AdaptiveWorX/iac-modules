# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Endpoints Module Variables

variable "vpc_id" {
  description = "VPC ID where endpoints will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sdlc, uat, prod)"
  type        = string
}

variable "route_table_ids" {
  description = "List of route table IDs for gateway endpoints"
  type        = list(string)
}

variable "endpoint_subnet_ids" {
  description = "List of subnet IDs for interface endpoints (typically private subnets)"
  type        = list(string)
  default     = []
}

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB gateway endpoint"
  type        = bool
  default     = false
}

variable "interface_endpoints" {
  description = "List of interface endpoints to create (e.g., ['ec2', 'ssm', 'ssmmessages', 'ec2messages'])"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

variable "prefix" {
  description = "Prefix for naming resources."
  type        = string
}

variable "fargate_type" {
  description = "Fargate type for ECS."
  type        = string
}

variable "cpu" {
  description = "CPU units for the ECS task definition."
  type        = string
}

variable "memory" {
  description = "Memory for the ECS task definition."
  type        = string
}

variable "cloudflare_version" {
  description = "Version of the cloudflared container image."
  type        = string
}

variable "tunnel_id" {
  description = "Cloudflare Tunnel ID."
  type        = string
}

variable "tunnel_token_arn" {
  description = "SSM Parameter Store ARN for the tunnel token."
  type        = string
}

variable "aws_region" {
  description = "AWS Region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "private_subnets" {
  description = "List of private subnets for the ECS service."
  type        = list(string)
}

variable "execution_role_arn" {
  description = "ARN of the IAM role that the ECS task uses."
  type        = string
}

variable "desired_count" {
  description = "Number of desired ECS service instances."
  type        = number
}
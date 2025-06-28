# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "vpc_id" {
  description = "VPC ID where route tables will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sdlc, uat, prod)"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "igw_id" {
  description = "Internet Gateway ID"
  type        = string
}

variable "eigw_id" {
  description = "Egress-only Internet Gateway ID (for IPv6)"
  type        = string
  default     = null
}

variable "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Whether NAT Gateway is enabled"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Whether IPv6 is enabled"
  type        = bool
  default     = true
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "data_subnet_ids" {
  description = "List of data subnet IDs"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

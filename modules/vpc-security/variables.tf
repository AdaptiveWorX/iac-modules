# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "vpc_id" {
  description = "VPC ID where NACLs will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "vpc_ipv6_cidr" {
  description = "VPC IPv6 CIDR block"
  type        = string
  default     = null
}

variable "default_network_acl_id" {
  description = "Default Network ACL ID to manage"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sdlc, uat, prod)"
  type        = string
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

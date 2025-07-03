# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sdlc, stage, prod)"
  type        = string
}

variable "client_id" {
  description = "Client identifier"
  type        = string
  default     = "adaptive"
}

variable "region_code" {
  description = "AWS region code (e.g., use1, usw2)"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "subnet_count" {
  description = "Number of subnets to create per tier"
  type        = number
  default     = 2
}

variable "subnet_bits" {
  description = "Number of additional bits for subnet CIDR calculation. If not provided, optimal sizes will be calculated automatically based on VPC size and AZ count."
  type = object({
    public  = number
    private = number
    data    = number
  })
  default = null  # Enable automatic calculation by default
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the VPC"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

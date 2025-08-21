# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# ============================================================================
# CORE VPC VARIABLES
# ============================================================================

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
  description = "Number of additional bits for subnet CIDR calculation. If not provided, optimal sizes will be calculated automatically."
  type = object({
    public  = number
    private = number
    data    = number
  })
  default = null
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

# ============================================================================
# NAT GATEWAY VARIABLES
# ============================================================================

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost optimization)"
  type        = bool
  default     = false
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to create. If null, will be determined by single_nat_gateway flag"
  type        = number
  default     = null
}

# ============================================================================
# VPC ENDPOINTS VARIABLES
# ============================================================================

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB VPC endpoint"
  type        = bool
  default     = false
}

variable "interface_endpoints" {
  description = "List of AWS services for which to create interface endpoints (e.g., ['ec2', 'ecs', 'ssm'])"
  type        = list(string)
  default     = []
}

# ============================================================================
# RAM SHARING VARIABLES
# ============================================================================

variable "share_with_accounts" {
  description = "List of AWS account IDs to share VPC resources with"
  type        = list(string)
  default     = []
}

variable "share_with_accounts_map" {
  description = "Map of AWS account IDs to account names for sharing VPC resources"
  type        = map(string)
  default     = {}
}

variable "share_with_org_unit" {
  description = "Share VPC resources with an AWS Organization unit"
  type        = bool
  default     = false
}

variable "org_unit_arn" {
  description = "ARN of the AWS Organization unit to share with"
  type        = string
  default     = null
}

# ============================================================================
# COMMON VARIABLES
# ============================================================================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

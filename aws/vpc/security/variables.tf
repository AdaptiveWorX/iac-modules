# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# ============================================================================
# CORE VARIABLES
# ============================================================================

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# Note: aws_region variable is provided by Terragrunt's generated provider configuration

# ============================================================================
# NACL VARIABLES
# ============================================================================

variable "enable_ssh_access" {
  description = "Enable SSH access in NACLs"
  type        = bool
  default     = false
}

variable "ssh_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "enable_rdp_access" {
  description = "Enable RDP access in NACLs"
  type        = bool
  default     = false
}

variable "rdp_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed for RDP access"
  type        = list(string)
  default     = []
}

# ============================================================================
# SECURITY GROUP VARIABLES
# ============================================================================

variable "create_web_sg" {
  description = "Create web tier security group"
  type        = bool
  default     = false
}

variable "create_app_sg" {
  description = "Create application tier security group"
  type        = bool
  default     = false
}

variable "create_database_sg" {
  description = "Create database tier security group"
  type        = bool
  default     = false
}

variable "create_bastion_sg" {
  description = "Create bastion host security group"
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Port for application tier"
  type        = number
  default     = 8080
}

variable "database_port" {
  description = "Port for database tier"
  type        = number
  default     = 3306
}

variable "bastion_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed for bastion access"
  type        = list(string)
  default     = []
}

# ============================================================================
# VPC PEERING VARIABLES
# ============================================================================

variable "peer_configs" {
  description = "List of VPC peering configurations"
  type = list(object({
    region          = string
    vpc_id          = string
    vpc_cidr        = string
    route_table_ids = list(string)
  }))
  default = []
}

# ============================================================================
# COMMON VARIABLES
# ============================================================================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

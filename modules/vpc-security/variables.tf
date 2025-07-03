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
  description = "Environment name (e.g., sdlc, stage, prod)"
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

variable "enable_ssh_access" {
  description = "Enable SSH access through NACLs. Should be false for production environments"
  type        = bool
  default     = false
}

variable "ssh_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed for SSH access. Only used if enable_ssh_access is true"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.ssh_allowed_cidr_blocks) > 0 || !var.enable_ssh_access
    error_message = "ssh_allowed_cidr_blocks must contain at least one CIDR block when enable_ssh_access is true"
  }
}

variable "enable_rdp_access" {
  description = "Enable RDP access through NACLs. Should be false for production environments"
  type        = bool
  default     = false
}

variable "rdp_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed for RDP access. Only used if enable_rdp_access is true"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.rdp_allowed_cidr_blocks) > 0 || !var.enable_rdp_access
    error_message = "rdp_allowed_cidr_blocks must contain at least one CIDR block when enable_rdp_access is true"
  }
}

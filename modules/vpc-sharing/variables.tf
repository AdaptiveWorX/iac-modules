# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "environment" {
  description = "Environment name (e.g., sdlc, stage, prod)"
  type        = string
}

variable "subnet_arns" {
  description = "List of subnet ARNs to share"
  type        = list(string)
}

variable "enable_org_sharing" {
  description = "Enable RAM sharing with AWS Organizations"
  type        = bool
  default     = true
}

variable "share_with_accounts" {
  description = "List of AWS account IDs to share with"
  type        = list(string)
  default     = []
}

variable "share_with_org_unit" {
  description = "Whether to share with an organization unit"
  type        = bool
  default     = false
}

variable "org_unit_arn" {
  description = "ARN of the organization unit to share with"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

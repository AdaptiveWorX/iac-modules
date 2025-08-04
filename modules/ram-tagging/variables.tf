# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# RAM Tagging Module - Variables

variable "environment" {
  description = "Environment name (e.g., sdlc, stage, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_name" {
  description = "Name of the shared VPC to find and tag"
  type        = string
}

# Optional Tags
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

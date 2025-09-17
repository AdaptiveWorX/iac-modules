# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the certificate is being deployed"
  type        = string
}

variable "purpose" {
  description = "Purpose of the certificate (regional or cloudfront)"
  type        = string
  default     = "regional"
}

variable "alert_email" {
  description = "Email address for certificate expiry alerts"
  type        = string
  default     = ""
}

variable "certificate_rotation_days" {
  description = "Days before expiry to trigger alerts"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

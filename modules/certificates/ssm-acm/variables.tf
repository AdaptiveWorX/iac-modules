# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module: certificates/ssm-acm
# Purpose: Variables for importing certificates from SSM to ACM

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region where certificates will be imported"
  type        = string
}

variable "deploy_cloudfront_cert" {
  description = "Whether to deploy a CloudFront certificate (only applies in us-east-1)"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address for certificate expiry notifications"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

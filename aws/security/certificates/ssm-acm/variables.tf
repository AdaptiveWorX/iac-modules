# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Note: aws_region variable is provided by Terragrunt's generated provider_config.tf
# Do not declare it here to avoid duplicate variable errors

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "deploy_cloudfront_cert" {
  description = "Whether to deploy CloudFront certificate (only in us-east-1)"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address for certificate expiry alerts"
  type        = string
  default     = ""
}

variable "force_new_certificate_arn" {
  description = "Force creation of new certificate ARN on update (true) or attempt in-place update (false)"
  type        = bool
  default     = false  # Default to in-place updates to preserve ARNs
}

variable "certificate_update_behavior" {
  description = "How to handle certificate updates: 'in-place' preserves ARN, 'recreate' forces new ARN"
  type        = string
  default     = "in-place"
  
  validation {
    condition     = contains(["in-place", "recreate"], var.certificate_update_behavior)
    error_message = "Update behavior must be either 'in-place' or 'recreate'."
  }
}

variable "enable_certificate_versioning" {
  description = "Enable certificate version tracking in SSM"
  type        = bool
  default     = false  # Set to false by default since the SSM parameter may not exist
}

variable "certificate_rotation_days" {
  description = "Number of days before expiry to trigger rotation warnings"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring for certificate operations"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain certificate backups in SSM"
  type        = number
  default     = 90
}

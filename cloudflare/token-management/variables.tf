# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "tokens" {
  description = "Map of Cloudflare API tokens to manage"
  type = map(object({
    token_value = string
    description = string
    purpose     = string
    environment = string
  }))
  sensitive = true
}

variable "token_prefix" {
  description = "Prefix for token names in Secrets Manager"
  type        = string
  default     = ""
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  default     = ""
}

variable "enable_rotation" {
  description = "Enable automatic rotation for tokens"
  type        = bool
  default     = false
}

variable "rotation_days" {
  description = "Number of days between automatic rotations"
  type        = number
  default     = 90
}

variable "rotation_check_days" {
  description = "Number of days between rotation checks"
  type        = number
  default     = 7
}

variable "enable_automatic_rotation" {
  description = "Enable Lambda-based automatic rotation"
  type        = bool
  default     = false
}

variable "enable_expiration_alerts" {
  description = "Enable CloudWatch alarms for token expiration"
  type        = bool
  default     = true
}

variable "alert_days_before_expiry" {
  description = "Days before expiry to trigger alert"
  type        = number
  default     = 14
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

// Copyright (c) Adaptive Technology, LLC.
// SPDX-License-Identifier: MPL-2.0

variable "role_name" {
  description = "Name of the IAM role for cross-account access"
  type        = string
}

variable "source_account_role_arn" {
  description = "ARN of the role in the source account that will assume this role"
  type        = string
}

variable "external_id" {
  description = "External ID to be used for assuming the role (for additional security)"
  type        = string
}

variable "rds_arns" {
  description = "List of RDS instance ARNs that this role can access"
  type        = list(string)
}

variable "rds_secret_arns" {
  description = "List of Secrets Manager ARNs containing RDS credentials"
  type        = list(string)
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs that this role can access for backups"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 
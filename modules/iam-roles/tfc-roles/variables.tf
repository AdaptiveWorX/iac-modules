# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

variable "aws_account_name" {
  type        = string
  description = "The name of the AWS account (e.g., secops, prod-app)"
}

variable "oidc_provider_arn" {
  type        = string
  description = "The ARN of the OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "The URL of the OIDC provider"
}

variable "oidc_audience" {
  type        = string
  description = "The audience value to verify in the OIDC token"
}

variable "organization" {
  type        = string
  description = "The Terraform Cloud organization name"
}

variable "project" {
  type        = string
  description = "The Terraform Cloud project name"
}

variable "workspace" {
  type        = string
  description = "The Terraform Cloud workspace name pattern"
}

variable "policy_files" {
  type        = list(string)
  description = "List of policy files to attach to the role"
}

variable "enable_cross_account" {
  type        = bool
  description = "Whether to enable cross-account access for this role"
  default     = false
}

variable "secops_account_id" {
  type        = string
  description = "The AWS account ID of the SecOps account (required if enable_cross_account is true)"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}
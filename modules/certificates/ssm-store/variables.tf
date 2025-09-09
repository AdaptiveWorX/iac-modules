# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# Module: certificates/ssm-store
# Purpose: Variables for storing certificates in SSM Parameter Store

variable "certificate_body" {
  description = "The certificate body (PEM format)"
  type        = string
  sensitive   = true
}

variable "private_key" {
  description = "The certificate private key (PEM format)"
  type        = string
  sensitive   = true
}

variable "certificate_chain" {
  description = "The certificate chain (PEM format)"
  type        = string
  sensitive   = true
}

variable "expiry_date" {
  description = "Certificate expiry date in YYYY-MM-DD format"
  type        = string
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.expiry_date))
    error_message = "Expiry date must be in YYYY-MM-DD format."
  }
}

variable "trusted_account_arns" {
  description = "List of AWS account ARNs that can assume the certificate-reader role"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

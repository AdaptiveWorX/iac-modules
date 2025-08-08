# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

variable "cloudflare_account_id" {
  description = "The Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "The Cloudflare zone ID (optional, for access applications)"
  type        = string
  default     = ""
}

variable "tunnel_name" {
  description = "Name of the Cloudflare tunnel"
  type        = string
}

variable "environment" {
  description = "Environment name (sdlc, stage, prod)"
  type        = string
  validation {
    condition     = contains(["sdlc", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: sdlc, stage, prod"
  }
}

variable "vpc_routes" {
  description = "List of VPC CIDR blocks to route through the tunnel"
  type = list(object({
    cidr        = string
    description = string
  }))
  default = []
}

variable "store_token_in_ssm" {
  description = "Whether to store the tunnel token in AWS SSM Parameter Store"
  type        = bool
  default     = true
}

variable "create_access_application" {
  description = "Whether to create a Zero Trust Access application"
  type        = bool
  default     = false
}

variable "access_domain" {
  description = "Domain for the Zero Trust Access application"
  type        = string
  default     = ""
}

variable "session_duration" {
  description = "Session duration for Zero Trust Access"
  type        = string
  default     = "24h"
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}
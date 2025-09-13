# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

variable "environment" {
  description = "Environment to deploy the Cloudflare tunnel instances in"
  type        = string
  default     = "prod"
}

variable "prefix" {
  description = "Prefix for naming resources."
  type        = string
}

variable "tunnel_token" {
  description = "The value of the Cloudflare tunnel token."
  type        = string
}